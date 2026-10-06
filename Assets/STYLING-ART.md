# Approved styling and mirror poses

Generated with Codex's built-in imagegen tool using Velvet's existing robot artwork as the character reference.

## Approved look

`styling-concept-v1.png` records the two-option preview. The user chose the **right** robot: matte black pointed tribal heart at her hip and a small silver navel barbell with a pale pink gem. The star on the left was not selected and is not implemented. No ribbon or clothing was added.

Design brief: Preserve the compact blue flower-headed robot, navy visor, mint pixel eyes, pink soles and exactly one existing pink ear cuff. Add a small tribal-heart hip tattoo and a tiny silver curved navel barbell with a pale pink gem; match the original soft lighting and toy material. Keep the belly free of logos.

The two cosmetic details are drawn by `Sources/BodyStyling.swift` into cached pose images, independently controlled by ownership and worn state. Each visible pose has its own shell placement; back views, deeply folded limbs and covering props conceal the relevant detail. The original silhouette alpha and hitbox remain intact. Art is transformed and pixel-treated with the original sprite.

## Mirror animation

`styling-sprites-v1.png`: transparent 2 × 2 atlas, four complete poses, appended at indices 124–127. Sequence: raise mirror → check reflection → confident pose or occasional side-eye. The atlas has no baked-in purchasable cosmetics.

Final generation prompt:

> Use case: identity-preserve. Asset type: four-pose native desktop robot mirror animation atlas, exactly TWO equal columns and TWO equal rows, transparent RGBA background, no grid lines, labels, numbers or text. The provided image is ONLY the exact character and material reference. Match the original standing robot from its first cell: very short chunky blue robot, oversized scalloped periwinkle blue flower head, dark navy rounded rectangular visor with mint pixel LED eyes and pink outer eye pixels, tiny LED smile, exactly ONE small existing pink ear cuff on viewer-right, plain BLUE belly, extremely short legs with pink soles. Preserve the exact proportions, hue, soft lighting and 3D toy material. No ribbon, necklace, tattoo, belly piercing, hair or clothing: accessories will be layered in the app. Full robot in every cell, identical physical scale and camera, consistent feet baseline, generous transparent safety margin. Each sprite visibly grips one tiny polished silver round hand mirror by its narrow handle in her left hand (viewer-right) held just outside the side of her large head. Mirror is physically connected to the gripping hand, small believable metal object, same studio illumination, subtle simplified reflection of her own blue head/navy visor where mirror faces camera. Row 1 cell 1: standing front three-quarter view, raises the hand mirror and looks at it, free hand at side, entire belly visible; row 1 cell 2: standing, gently turns head toward mirror, free hand on hip, torso still front-facing and blue belly unobstructed; row 2 cell 1: confidently serves a tiny cheeky pose looking toward viewer, mirror held slightly outward away from belly, free hand on hip; row 2 cell 2: same scale, gives viewer a devastating tiny pixel side-eye, mirror still held beside head, free arm at side. No crossing arms over torso. Four complete separate sprites, one robot and one held mirror per cell. Do not invent extra ear piercings, disconnected reflections outside the mirror, detached props, extra fingers, ground planes, shadows, sparkles or decorative fragments. Actual transparent background; plain unmarked belly crucial. Keep legs very short and head size constant.

Native `--styling-smoke` writes four contact sheets showing all 128 poses with both cosmetics, plus the actual desktop-size mirror pose. It uses a temporary profile.
