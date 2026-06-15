#!/usr/bin/env bash
# Re-fetch every asset TAKEN IN PARIS uses into models/ + audio/ (run from models/).
# Bespoke Meshy characters + custom landmarks come from R2; world dressing from the CC0
# library; audio is synthesized (audio/synth.py) and mirrored to R2. Godot extracts embedded
# textures on --import, so only the .glb / .ogg files are needed. The cast GLBs ship
# texture-optimized (webp @1024); a gltf-transform pass keeps any unoptimized ones small.
set -e
cd "$(dirname "$0")"
GA="https://preview.myapping.com/godot-assets"
R2_LM="https://preview.myapping.com/cloud-qk4s0rbnain9fg6p8psp/models"      # custom landmarks
R2_CAST="https://preview.myapping.com/cloud-l05zerte6knxbfqgrpdq/models"    # bespoke Meshy cast
R2_AUDIO="https://preview.myapping.com/cloud-l05zerte6knxbfqgrpdq/audio"

echo "custom landmarks (Eiffel, Haussmann cafe)..."
for n in eiffel_tower haussmann_cafe; do
  curl -sfL "$R2_LM/$n.glb" -o "$n.glb" && echo "  $n.glb" || echo "  MISSING $n.glb (regenerate via Meshy)"
done

echo "bespoke Meshy cast (realistic, rigged: idle/walk/run/talk/gesture/sit/lean, +Z facing)..."
for n in spy_hero daughter henchman waiter cop flower_seller musician informant; do
  curl -sfL "$R2_CAST/$n.glb" -o "$n.glb" && echo "  $n.glb" || echo "  MISSING $n.glb (regenerate via Meshy)"
done
cp -f daughter.glb kid.glb   # the playing kid reuses the realistic child model

echo "library guards (rank-and-file sentries / cameras)..."
curl -sfL "$GA/realistic_characters/soldier.glb"  -o guard_soldier.glb
curl -sfL "$GA/realistic_characters/vanguard.glb" -o guard_vanguard.glb

echo "kk_city street kit (benches, lamps, hydrants, cars, trees)..."
for n in bench streetlight firehydrant trash_A trash_B dumpster bush \
         car_sedan car_hatchback car_taxi car_police car_stationwagon; do
  curl -sfL "$GA/props/kk_city/$n.glb" -o "kc_$n.glb"
done
curl -sfL "$GA/props/q_trees/Birch_3.glb" -o q_birch.glb
curl -sfL "$GA/props/q_unature/$(curl -sfL "$GA/manifest.json" | grep -o 'q_unature/[A-Za-z0-9_]*[Tt]ree[A-Za-z0-9_]*\.glb' | head -1 | sed 's#.*/##')" -o q_tree.glb || true

echo "library cafe + realistic dressing..."
curl -sfL "$GA/props/kk_restaurant/chair_a.glb"     -o chair.glb
curl -sfL "$GA/props/kk_restaurant/chair_b.glb"     -o chair_b.glb
curl -sfL "$GA/props/kk_restaurant/crate.glb"       -o crate.glb
curl -sfL "$GA/props/kk_restaurant/door_a.glb"      -o door.glb
curl -sfL "$GA/props/kk_restaurant/food_dinner.glb" -o food.glb
for p in ms_barrier_road ms_control_box ms_board_message ms_cabinet_basic ms_cable_reel \
         ms_brick_pile ms_chair_sun ms_candle ms_carpet ms_campfire; do
  curl -sfL "$GA/props/vostok_realistic/$p.glb" -o "v_$p.glb"
done

echo "audio (synthesized soundscape, mirrored to R2)..."
mkdir -p ../audio
for a in amb_street amb_cafe amb_gallery amb_crypt music_explore music_tension accordion \
         sfx_collect sfx_deduce sfx_takedown sfx_spotted sfx_alarm sfx_pick_tick sfx_pick_ok \
         sfx_pick_fail sfx_door sfx_heli sfx_camera sfx_ui sfx_note; do
  curl -sfL "$R2_AUDIO/$a.ogg" -o "../audio/$a.ogg" || echo "  MISSING audio/$a.ogg (regen: python3 ../audio/synth.py)"
done

# Keep the web export small: downscale any GLB textures over 1024 (the cast already ships
# at 1024; the Eiffel landmark goes to 512).
if command -v npx >/dev/null 2>&1; then
  echo "optimizing GLB textures (gltf-transform)..."
  GT="npx --yes @gltf-transform/cli@latest"
  for m in haussmann_cafe guard_soldier guard_vanguard; do
    [ -f "$m.glb" ] && $GT resize "$m.glb" "$m.glb" --width 1024 --height 1024 >/dev/null 2>&1 || true
  done
  [ -f eiffel_tower.glb ] && $GT resize eiffel_tower.glb eiffel_tower.glb --width 512 --height 512 >/dev/null 2>&1 || true
else
  echo "(skip texture optimization - npx not found; install Node for a smaller .pck)"
fi

echo "done. now run: godot --headless --path .. --import"
