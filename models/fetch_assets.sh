#!/usr/bin/env bash
# Re-fetch every asset TAKEN IN PARIS uses into models/ + audio/ (run from models/).
# Custom Meshy characters/landmarks come from the build's R2 bucket; world dressing from the
# CC0 library; audio is synthesized (audio/synth.py) and mirrored to R2. Godot extracts
# embedded textures on --import, so only the .glb / .ogg files are needed.
# After fetching, GLB textures are downscaled (gltf-transform) to keep the web .pck small.
set -e
cd "$(dirname "$0")"
GA="https://preview.myapping.com/godot-assets"
R2="https://preview.myapping.com/cloud-qk4s0rbnain9fg6p8psp/models"
R2_AUDIO="https://preview.myapping.com/cloud-l05zerte6knxbfqgrpdq/audio"

echo "custom Meshy assets (hero, daughter, henchman, landmarks)..."
for n in spy_hero henchman daughter eiffel_tower haussmann_cafe; do
  curl -sfL "$R2/$n.glb" -o "$n.glb" && echo "  $n.glb" || echo "  MISSING $n.glb (regenerate via Meshy)"
done

echo "library characters (rigged: idle/walk/run)..."
curl -sfL "$GA/realistic_characters/soldier.glb"  -o guard_soldier.glb
curl -sfL "$GA/realistic_characters/vanguard.glb" -o guard_vanguard.glb
curl -sfL "$GA/realistic_characters/warden.glb"   -o informant.glb

echo "Parisian NPC cast (distinct rigged humanoids)..."
# These are reskinned library humanoids (tinted per-NPC in code). Swap any of these for a
# bespoke Meshy .glb of the same name to upgrade a specific character's look.
cp -f informant.glb     waiter.glb
cp -f guard_vanguard.glb musician.glb
cp -f guard_soldier.glb  cop.glb
cp -f informant.glb     flower_seller.glb
cp -f daughter.glb      kid.glb

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

# Downscale GLB textures so the web export stays small (characters 1024, eiffel 512).
if command -v npx >/dev/null 2>&1; then
  echo "optimizing GLB textures (gltf-transform)..."
  GT="npx --yes @gltf-transform/cli@latest"
  for m in spy_hero daughter henchman informant guard_soldier guard_vanguard \
           waiter musician cop flower_seller kid haussmann_cafe; do
    [ -f "$m.glb" ] && $GT resize "$m.glb" "$m.glb" --width 1024 --height 1024 >/dev/null 2>&1 || true
  done
  [ -f eiffel_tower.glb ] && $GT resize eiffel_tower.glb eiffel_tower.glb --width 512 --height 512 >/dev/null 2>&1 || true
else
  echo "(skip texture optimization - npx not found; install Node for a smaller .pck)"
fi

echo "done. now run: godot --headless --path .. --import"
