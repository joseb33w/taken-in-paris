#!/usr/bin/env bash
# Re-fetch every model TAKEN IN PARIS uses into this directory (run from models/).
# Custom Meshy assets come from the build's R2 bucket; library assets from the CC0 library.
# Godot extracts the embedded textures on --import, so only the .glb files are needed.
set -e
cd "$(dirname "$0")"
GA="https://preview.myapping.com/godot-assets"
R2="https://preview.myapping.com/cloud-qk4s0rbnain9fg6p8psp/models"

echo "custom Meshy assets..."
for n in spy_hero henchman daughter eiffel_tower haussmann_cafe; do
  curl -sfL "$R2/$n.glb" -o "$n.glb" && echo "  $n.glb" || echo "  MISSING $n.glb (regenerate via Meshy)"
done

echo "library characters..."
curl -sfL "$GA/realistic_characters/soldier.glb"  -o guard_soldier.glb
curl -sfL "$GA/realistic_characters/vanguard.glb" -o guard_vanguard.glb
curl -sfL "$GA/realistic_characters/warden.glb"   -o informant.glb

echo "library cafe props..."
curl -sfL "$GA/props/kk_restaurant/chair_a.glb"     -o chair.glb
curl -sfL "$GA/props/kk_restaurant/chair_b.glb"     -o chair_b.glb
curl -sfL "$GA/props/kk_restaurant/crate.glb"       -o crate.glb
curl -sfL "$GA/props/kk_restaurant/door_a.glb"      -o door.glb
curl -sfL "$GA/props/kk_restaurant/food_dinner.glb" -o food.glb

echo "library realistic dressing (vostok)..."
for p in ms_barrier_road ms_control_box ms_board_message ms_cabinet_basic ms_cable_reel ms_brick_pile ms_chair_sun ms_candle ms_carpet ms_campfire; do
  curl -sfL "$GA/props/vostok_realistic/$p.glb" -o "v_$p.glb"
done
echo "done. now run: godot --headless --path .. --import"
