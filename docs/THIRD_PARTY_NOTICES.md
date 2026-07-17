# MI Academy — Third Party Notices

> **Generated:** 2026-07-17
> **Owner:** Game & Experience Lead

This file contains attribution notices for third party software used in MI Academy game packages.

---

## 1. Flutter/Dart Dependencies

### 1.1 equatable

```
Package: equatable
Version: ^2.0.5
License: BSD-3-Clause
Repository: https://github.com/felangel/equatable
Copyright: 2020 Felix Angelov
License Text: https://github.com/felangel/equatable/blob/master/LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Files used:** All model classes in `mi_game_core`, `mi_game_ui`, `mi_game_audio`, etc.

### 1.2 uuid

```
Package: uuid
Version: ^4.4.0
License: MIT
Repository: https://github.com/DaveNot英国/uuid
Copyright: 2011, Robert Kieffer
License Text: https://github.com/DaveNot英国/uuid/blob/main/LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Files used:** Attempt IDs, game snapshot IDs in `mi_game_core`.

### 1.3 audioplayers

```
Package: audioplayers
Version: ^6.0.0
License: Apache-2.0
Repository: https://github.com/bluefireteam/audioplayers
Copyright: 2019 Blue Fire Team
License Text: https://github.com/bluefireteam/audioplayers/blob/master/LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

**Files used:** `mi_game_audio/lib/src/services/audio_player_service.dart`

### 1.4 mocktail

```
Package: mocktail
Version: ^1.0.3
License: BSD-3-Clause
Repository: https://github.com/felangel/mocktail
Copyright: 2021 Felix Angelov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Files used:** Test files in `mi_game_testing/`, `mi_game_core/test/`.

---

## 2. Dev Dependencies

### 2.1 flutter_lints

```
Package: flutter_lints
Version: ^4.0.0
License: MIT
Repository: https://github.com/flutter-community/flutter_lints

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 3. Future Dependencies (Wave 3+)

### 3.1 flame

```
Package: flame
Version: ^1.18.0 (planned)
License: MIT
Repository: https://github.com/flame-engine/flame
License File: https://github.com/flame-engine/flame/blob/main/LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Intended use:** Math Race, Math Supermarket, Robot Commands (Waves 3-4)

---

## 4. No External Assets

At the time of this document, no external images, audio, fonts, or other media assets have been integrated into the game packages. All game assets are planned as:
- Custom in-house creation (proprietary to MI Academy)
- CC0 assets (to be created/funded separately)
- Custom SVG icons from Material Icons / Phosphor Icons

When any asset is integrated, it will be added to this file with:
- Source URL
- Asset file path in repository
- License
- Attribution text
- File hash (SHA-256) for verification

---

## 5. License Summary

| Package | License | Approved |
|---------|---------|---------|
| equatable | BSD-3 | ✅ |
| uuid | MIT | ✅ |
| audioplayers | Apache-2.0 | ✅ |
| mocktail | BSD-3 | ✅ |
| flutter_lints | MIT | ✅ |
| flame (planned) | MIT | ✅ (pending Wave 3) |
| flame_audio (planned) | MIT | ✅ (pending Wave 3) |

No GPL, AGPL, or unknown-license dependencies are in use.
