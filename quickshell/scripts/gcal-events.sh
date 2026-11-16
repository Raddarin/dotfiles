#!/usr/bin/env bash
# Hämtar events från alla valda Google-kalendrar och skriver en JSON-array till stdout.
#
# Användning:  gcal-events.sh FROM TO      (YYYY-MM-DD, TO är exklusivt)
# Exempel:     gcal-events.sh 2026-11-01 2026-12-07
#
# Varje event:
#   { title, start, end, allDay, color, cal, location, desc }
# start/end är ISO-tid med tidszon (eller bara datum för heldagsevent, där end är exklusivt).
# color = eventets egen färg (colorId) om den är satt, annars kalenderns färg.

set -u

CONFIG_FILE="${GCAL_CONFIG:-$HOME/.config/quickshell/scripts/codes_new.json}"
CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/gcal_access_token.json"

die() {
	echo "$*" >&2
	exit 1
}

command -v jq >/dev/null 2>&1 || die "jq saknas"
command -v curl >/dev/null 2>&1 || die "curl saknas"
[ -r "$CONFIG_FILE" ] || die "Hittar inte $CONFIG_FILE"

FROM="${1:-}"
TO="${2:-}"
[ -n "$FROM" ] && [ -n "$TO" ] || die "Användning: $0 FROM TO (YYYY-MM-DD)"

TIME_MIN=$(date -d "$FROM 00:00:00" --iso-8601=seconds 2>/dev/null) || die "Ogiltigt datum: $FROM"
TIME_MAX=$(date -d "$TO 00:00:00" --iso-8601=seconds 2>/dev/null) || die "Ogiltigt datum: $TO"

# ---------- Access token (cachas tills den går ut) ----------
get_token() {
	local now exp tok resp expires_in
	now=$(date +%s)

	if [ -r "$CACHE_FILE" ]; then
		exp=$(jq -r '.expires_at // 0' "$CACHE_FILE" 2>/dev/null)
		tok=$(jq -r '.access_token // empty' "$CACHE_FILE" 2>/dev/null)
		if [ -n "$tok" ] && [ "${exp:-0}" -gt $((now + 60)) ]; then
			echo "$tok"
			return 0
		fi
	fi

	local client_id client_secret refresh_token
	client_id=$(jq -r '.client_id' "$CONFIG_FILE")
	client_secret=$(jq -r '.client_secret' "$CONFIG_FILE")
	refresh_token=$(jq -r '.refresh_token' "$CONFIG_FILE")

	resp=$(curl -s -X POST https://oauth2.googleapis.com/token \
		-d "client_id=$client_id" \
		-d "client_secret=$client_secret" \
		-d "refresh_token=$refresh_token" \
		-d "grant_type=refresh_token")

	tok=$(jq -r '.access_token // empty' <<<"$resp")
	[ -n "$tok" ] || return 1

	expires_in=$(jq -r '.expires_in // 3000' <<<"$resp")
	(
		umask 077
		jq -n --arg t "$tok" --argjson e $((now + expires_in)) \
			'{access_token: $t, expires_at: $e}' >"$CACHE_FILE"
	)
	echo "$tok"
}

ACCESS_TOKEN=$(get_token) || die "Kunde inte hämta access_token. Kolla dina uppgifter!"
AUTH="Authorization: Bearer $ACCESS_TOKEN"
API="https://www.googleapis.com/calendar/v3"

# ---------- Eventfärger: colorId -> hex ----------
COLORS=$(curl -s -H "$AUTH" "$API/colors" |
	jq -c '[ (.event // {}) | to_entries[] | { (.key): .value.background } ] | add // {}') || COLORS='{}'
[ -n "$COLORS" ] || COLORS='{}'

# ---------- Kalendrar (bara de som är markerade som synliga i Google Calendar) ----------
CAL_RESPONSE=$(curl -s -H "$AUTH" -G "$API/users/me/calendarList" \
	--data-urlencode "fields=items(id,summary,summaryOverride,backgroundColor,selected)")

if jq -e '.error' >/dev/null 2>&1 <<<"$CAL_RESPONSE"; then
	die "Google API: $(jq -r '.error.message // "okänt fel"' <<<"$CAL_RESPONSE")"
fi

CALS=$(jq -c '(.items // []) | map(select(.selected == true)) | .[]' <<<"$CAL_RESPONSE")

# ---------- Hämta events per kalender, parallellt ----------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
echo '[]' >"$TMP/0.json"

i=0
while IFS= read -r cal; do
	[ -n "$cal" ] || continue
	i=$((i + 1))
	(
		id=$(jq -r '.id' <<<"$cal")
		name=$(jq -r '.summaryOverride // .summary // .id' <<<"$cal")
		calcolor=$(jq -r '.backgroundColor // "#4285F4"' <<<"$cal")
		enc_id=$(jq -rn --arg s "$id" '$s | @uri')

		curl -s -H "$AUTH" -G "$API/calendars/$enc_id/events" \
			--data-urlencode "timeMin=$TIME_MIN" \
			--data-urlencode "timeMax=$TIME_MAX" \
			--data-urlencode "singleEvents=true" \
			--data-urlencode "orderBy=startTime" \
			--data-urlencode "maxResults=2500" \
			--data-urlencode "fields=items(id,status,summary,description,location,colorId,start,end,attendees(self,responseStatus))" |
			jq -c --arg cal "$name" --arg calcolor "$calcolor" --argjson colors "$COLORS" '
				[ .items[]?
					| select(.status != "cancelled")
					| select([ (.attendees // [])[] | select(.self == true and .responseStatus == "declined") ] | length == 0)
					| {
						title:    (.summary // "(Utan titel)"),
						start:    (.start.dateTime // .start.date),
						end:      (.end.dateTime // .end.date),
						allDay:   (.start.date != null),
						color:    (($colors[(.colorId // "")]) // $calcolor),
						cal:      $cal,
						location: (.location // ""),
						desc:     ((.description // "") | gsub("<[^>]*>"; " ") | .[0:400])
					}
				]' >"$TMP/$i.json" 2>/dev/null || echo '[]' >"$TMP/$i.json"
	) &
done <<<"$CALS"
wait

jq -s -c 'add // [] | sort_by(.start)' "$TMP"/*.json
