# MI Character Guide — Robot hướng dẫn MI

- **Owner:** Dev 4 | **Date:** 2026-07-17 | **Status:** Direction chosen, production pending

## 1. Personality (normative for art, animation, copy, voice)

Thân thiện · bình tĩnh · tò mò · khích lệ. Không phán xét, không chế giễu,
không gây áp lực, không nói nhiều. MI là *bạn đồng hành* đứng cạnh bài học,
không phải nhân vật chính chiếm màn hình.

## 2. Ba hướng thiết kế đã khảo sát

### Direction A — "Bubble Bot" (viên nang tròn)
Thân capsule mềm, tay chân ngắn hình giọt nước, mắt to kiểu mascot.
- ✓ Rất thân thiện với nhóm 5–7.
- ✗ Nhóm 11–12 sẽ thấy "em bé"; silhouette dễ trùng với nhiều mascot app trẻ em;
  khó thể hiện "thinking/strategy".

### Direction B — "Screen-Face Companion" (mặt màn hình) ★ CHỌN
Đầu chữ nhật bo góc lớn (radius.xLarge) với **mặt là màn hình** hiển thị mắt/
miệng bằng hình học đơn giản; thân nhỏ hơn đầu, tay mềm không khớp; một ăng-ten
tròn; nổi nhẹ trên mặt đất (không chân → không cần rig đi bộ phức tạp, pose
"walk" = trượt + nhún).
- ✓ Biểu cảm = đổi hình vẽ trên màn hình mặt → cực rẻ để animate (Rive: 1 rig,
  swap face states), cực dễ thu thành icon (chỉ cần cái đầu).
- ✓ Silhouette riêng biệt (đầu to + ăng-ten tròn), scale tốt từ 24 px đến full.
- ✓ Trung tính độ tuổi: sạch sẽ với 11–12, mặt vui với 5–7.
- ✓ Màn hình mặt đổi màu theo trạng thái (thinking = info, celebrating = accent).
- Khác biệt hoá đã kiểm tra: không mắt đơn (EVE/Cozmo), không bánh xích, không
  hộp vuông cứng (Baymax/BB-8/Emo đều khác cấu trúc). Dev 3 similarity-check
  trước production.

### Direction C — "Orb Scout" (quả cầu bay)
Quả cầu nổi với vòng sáng, mắt lớn.
- ✓ Animate rẻ nhất. ✗ Không có tay → không point/hold/clap được (yêu cầu §11);
  silhouette gần các "floating orb assistant" phổ biến.

**Quyết định: Direction B.** Lý do chính: đáp ứng đủ 12 biểu cảm + 11 pose với
chi phí rig thấp nhất, icon-able, không trùng thương hiệu.

## 3. Construction rules

- Tỷ lệ: đầu : thân = 1.6 : 1. Tổng cao ≈ 3 đơn vị đầu-nửa.
- Bảng màu: thân `#F4F4FF` + viền `#2D2D5F` 2.5 px; màn hình mặt `#2D2D5F`;
  nét mặt phát sáng `#7DEFFF`; điểm nhấn `color.primary`; ăng-ten `color.accent`.
- Không vũ khí, không răng, không mắt đỏ, không yếu tố đáng sợ ở mọi trạng thái.
- MI chiếm tối đa ~18% chiều rộng màn hình khi đứng cạnh nội dung; full-size chỉ
  trong onboarding/completion.

## 4. Expression set (12) — asset IDs

`character_mi_face_<expression>_v01` :
neutral, welcome, thinking, hinting, happy, celebrating, encouraging,
surprised, listening, idle_sleep, error_recovery, goodbye.

Quy tắc biểu cảm: sai → MI *thinking/hinting* (nghiêng đầu, mặt màu info),
tuyệt đối không lắc đầu mạnh, không dấu X, không mặt buồn sâu.

## 5. Pose set (11) — asset IDs

`character_mi_pose_<pose>_v01` :
point_left, point_right, point_up, point_down, hold_sign, hold_book,
hold_star, walk (glide), hover (fly nhẹ — đã duyệt trong direction B),
wave, clap.

## 6. Production pipeline

1. Concept sheet Direction B (3 góc + turnaround) → Dev 3 similarity review.
2. Master vector (SVG source) → Rive rig: 1 body + face-state machine.
3. Exports: Rive file cho animation runtime; WebP stills cho contexts tĩnh;
   `icon_mi_head` 24/48/96 cho icon.
4. Manifest entries + license (`MI-Academy-Owned`) trước khi integrate.

Reduced-motion: mọi trạng thái MI có bản tĩnh (still frame được chọn sẵn,
không phải frame ngẫu nhiên).

## 7. Voice pairing

Giọng MI (chi tiết trong `docs/audio/AUDIO_DIRECTION.md`): ấm, chậm vừa,
không cao chói, không kiểu quảng cáo. Mỗi expression có tối đa 1 cue âm ngắn
(< 700 ms) đi kèm, trừ celebrating (≤ 2 s).
