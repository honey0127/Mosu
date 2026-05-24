Clean except one lint at community_repository.dart:63 — dart format wrapped a long pre-existing if (...) throw onto two lines, which trips the braces lint. I'll brace those two sibling branches so analyze stays clean.


읽기 파일 1개, 편집됨 파일 1개, 실행됨 명령 1개
All four files clean. Let me run a full-project analyze to ensure nothing else broke.

실행됨
Analyze entire lib for regressions
All my changed files are clean. The 19 remaining issues are all pre-existing in character_room_screen.dart (deprecations, unused _ShirtPatch/_PantsPatch) — a file I didn't touch this task, so I left them.

Done — full sync is wired up
Flow: change avatar on 마이 page → it now also writes to the Supabase profiles.photo_url → the room member tile renders it. Three value types:

Avatar choice	Stored in photo_url	Rendered in rooms as
Character (emoji)	animal:🐰	the emoji
Gallery photo	uploaded to Storage → public URL	the photo
Reset to default	'' (cleared)	name's first letter
Files changed
community_repository.dart — added uploadAvatar(File) → uploads to the avatars bucket, returns a public URL.
my_page_screen.dart — every avatar change now pushes to Supabase (_syncAvatarToCommunity); gallery picks upload first; _ProfileAvatar renders network URLs.
room_detail_screen.dart — _MemberTile now shows photo / emoji / letter.
0002_avatars_storage.sql — new Storage bucket + RLS policies.
⚠️ One required setup step (or gallery upload fails)
You must create the Storage bucket in Supabase. Easiest: open Supabase Dashboard → SQL Editor, paste the contents of 0002_avatars_storage.sql, and run it. That creates a public avatars bucket and policies letting each user write only to their own folder.

(Or do it by hand: Storage → New bucket named avatars, check Public, then add the upload policies.)

Until that's done, the emoji/character option still works (it's just text, no upload). Gallery photos will fail the upload and fall back to showing only on your own device with a "업로드엔 실패했어요" notice.

Notes
The avatar attaches to your anonymous Supabase session (same identity the community already uses), so it persists as long as that session does.
Other members see your new picture after a pull-to-refresh / re-entering the room.
I couldn't run the app from here — please test on your device: set a character avatar, set a gallery photo, then open a room to confirm both render.
Want me to also surface avatars in the room list cards, or add a handle/display-name editor so members show real names instead of "익명 탐험가"?