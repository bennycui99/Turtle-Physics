globals[damping]

patches-own[density]

turtles-own [
  mass
  vx  ; Horizontal velocity
  vy  ; Vertical velocity
  ax  ; Horizontal acceleration
  ay  ; Vertical acceleration
  newxcor
  newycor
  radius
  restitution
]

to setup
  clear-all

  set damping 1 - damping-co  ; Velocity damping per tick (simulates air resistance)
  create-turtles ball-num [

    setxy random-xcor random-ycor
    set shape "circle"
    set radius 1.0 + random-float 1.5  ; Random radius between 0.5 and 2.0
    set size 2 * radius  ; Visual size based on collision radius

    set mass radius ^ 2
    set vx random-float 4 - 2  ; Random initial velocity
    set vy random-float 4 - 2
    set ax 0
    set ay 0
    set restitution 0.6  ; Bounciness between 0.7 and 1.0

  ]
  reset-ticks
end

to go
  click
  apply-forces      ; Apply gravity
  update-velocities ; Integrate acceleration into velocity
  apply-damping     ; Reduce velocity due to damping
  detect-collisions ; Resolve collisions between turtles
  move-turtles      ; Update positions and handle edge bouncing
  tick
end

to apply-forces
  ask turtles [
    set ay ay - gravity  ; Gravity affects vertical acceleration
  ]
end

to update-velocities
  ask turtles [
    set vx vx + ax
    set vy vy + ay
    set ax 0  ; Reset acceleration
    set ay 0
  ]
end

to apply-damping
  set damping 1 - damping-co  ; Velocity damping per tick (simulates air resistance)
  ask turtles [
    set vx vx * damping
    set vy vy * damping
  ]
end

to detect-collisions
  ;; We only handle each pair once: for turtle i, we only compare with turtles j where j > i.
  ask turtles [
    let me self
    ask other turtles with [who > [who] of me] [

      ;; Compute the vector between me and the other turtle
      let detx (xcor - [xcor] of me)
      let dety (ycor - [ycor] of me)
      let dist distance me
      let sum-r (radius + [radius] of me)

      ;; Check overlap
      if dist  < sum-r [
        ;; If dist = 0, skip or nudge it to avoid divide-by-zero
        if dist = 0 [
          set dist 0.00000001
        ]

        ;;---------------------------------
        ;; (1) Separate the overlapping turtles
        ;;---------------------------------
        let overlap (sum-r - dist)
        let nx (detx / dist)
        let ny (dety / dist)


        let halfOverlap (overlap / 2)

        ;; Move this turtle away
        set newxcor xcor + (nx * halfOverlap)
        set newycor ycor + (ny * halfOverlap)




        ;; Move the other turtle away
        ask me [
          set newxcor xcor - (nx * halfOverlap)
          set newycor ycor - (ny * halfOverlap)
        ]

        ;;---------------------------------
        ;; (2) Compute new velocities (1D elastic collision)
        ;;---------------------------------
        let m1 mass
        let m2 [mass] of me

        let vx1 vx
        let vy1 vy
        let vx2 [vx] of me
        let vy2 [vy] of me

        set vx1 lim vx1
        set vy1 lim vy1
        set vx2 lim vx2
        set vy2 lim vy2


        ;; Compute normal velocity components
        let un1 (vx1 * nx + vy1 * ny)
        let un2 (vx2 * nx + vy2 * ny)

        ;; Compute tangential velocity components (unchanged by elastic collision)
        let ut1 (vx1 * -1 * ny + vy1 * nx)
        let ut2 (vx2 * -1 * ny + vy2 * nx)

        ;; Elastic collision formulas
        let un1Prime ((un1 * (m1 - m2) + 2 * m2 * un2) / (m1 + m2))

        let un2Prime ((un2 * (m2 - m1) + 2 * m1 * un1) / (m1 + m2))

        ;; Recombine into (vx, vy)
        set vx (un1Prime * nx + ut1 * -1 * ny)
        set vy (un1Prime * ny + ut1 *  nx)

        ask me [
          set vx (un2Prime * nx + ut2 * -1 * ny)
          set vy (un2Prime * ny + ut2 *  nx)
        ]
      ]
    ]
  ]
end

to move-turtles
  ask turtles [

    ask patch-here[
      set pcolor [color]of myself
      set density 100
    ]

    ; Calculate new position
    set newxcor xcor + vx
    set newycor ycor + vy
    if 1 = 1[
    ; Bounce off horizontal edges
    if abs newxcor > max-pxcor - 1.5 [
      set vx (-1 * vx * restitution)
      set newxcor (sign newxcor) * (max-pxcor - 1.5)
    ]

    ; Bounce off vertical edges
    if abs newycor > max-pycor - 1.5[
      set vy (-1 * vy * restitution)
      set newycor (sign newycor) * (max-pycor - 1.5)
    ]
    ]
    setxy newxcor newycor
  ]

  ask patches[
    set density density * 0.9
    set pcolor scale-color pcolor density 0 100
  ]

end

to-report sign [number]
  ifelse number > 0
  [ report 1
  ][
    ifelse number < 0[
      report -1
    ][
      report 0
    ]
  ]
end

to-report lim [number]
  ifelse  number > 1E30[
    report 1E30][
    ifelse number < -1E30[
      report -1E30
    ][
     report number
    ]
  ]
end

to up

  ask turtles[
    set ay ay + 1
  ]
end

to click
  if mouse-down?[
    let x mouse-xcor
    let y mouse-ycor
    ask turtles[
      let d distancexy x y
      set ax ax + ( x - xcor ) / d * 0.05 / mass
      set ay ay + ( y - ycor ) / d * 0.05 / mass
    ]
  ]


end
@#$#@#$#@
GRAPHICS-WINDOW
202
10
523
332
-1
-1
2.872
1
10
1
1
1
0
1
1
1
-54
54
-54
54
0
0
1
ticks
30.0

BUTTON
9
15
72
48
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
83
15
146
48
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
60
177
93
gravity
gravity
0
0.05
0.014
0.001
1
NIL
HORIZONTAL

SLIDER
5
96
177
129
damping-co
damping-co
0
0.05
0.0
0.001
1
NIL
HORIZONTAL

SLIDER
5
133
177
166
ball-num
ball-num
0
100
24.0
1
1
NIL
HORIZONTAL

BUTTON
6
178
69
211
NIL
up
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model demonstrates a simple 2D physics simulation in NetLogo. Each turtle has properties such as **mass**, **radius**, and **velocity**. The model applies:

- **Gravity**, pulling turtles downward,  
- **Wall collisions**, which bounce the turtles off the edges of the world,  
- **Turtle-turtle collisions**, modeling elastic collisions between circular objects.

It showcases how to update positions, velocities, and detect collisions in each time step to create a rudimentary “physics engine” in NetLogo.

---

## HOW IT WORKS

1. **Turtle Variables**  
   Each turtle has:  
   - `vx` / `vy`: Velocity in the x/y directions,  
   - `mass`: Used in collision calculations,  
   - `radius`: Used to check if two turtles overlap.

2. **Gravity**  
   A small negative constant is added to `vy` every tick, causing a downward acceleration.

3. **Movement**  
   Each turtle’s position (`xcor`, `ycor`) is updated by adding (`vx`, `vy`) once per tick.

4. **Boundary Collisions**  
   When a turtle crosses a boundary, it is pushed back into the valid area, and its velocity component (x or y) is reversed.

5. **Turtle-Turtle Collisions**  
   - The distance between two turtles is compared to the sum of their radii. If they overlap, they are first separated.  
   - Then, their velocities are updated using simplified **elastic collision** formulas based on their masses.

---

## HOW TO USE IT

1. **Buttons**  
   - **Setup**: Clears the world and creates a specified number of turtles with random positions, velocities, and masses.  
   - **Go**: Repeatedly applies gravity, moves turtles, and checks for collisions in each tick.
   - **Up**: Add upward acceration to turtles
   - **Mouse click**: Add Force to turtles which points at the mouse location

2. **Initial Conditions**  
   - By default, 20 turtles are created, each with random properties (mass, velocity, radius). You can modify these values in the code or by adding a slider in the Interface tab.

3. **Running the Model**  
   1. Click **Setup** to initialize.  
   2. Click **Go** to start the simulation.  
   3. Observe how turtles move, bounce off walls, and collide with each other.

---

## THINGS TO NOTICE

- **Mass Effect**: When a light turtle collides with a heavier one, the lighter turtle’s velocity changes more dramatically.  
- **Energy Exchange**: In perfectly elastic collisions, kinetic energy is conserved. Turtles may exchange velocities but the total system energy (minus any gravity potential changes) remains roughly the same.  
- **Gravity**: Notice how gravity accelerates turtles downward. They will bounce on the “floor” boundary repeatedly.

---

## THINGS TO TRY

1. **Vary Gravity**  
   Change the gravity constant in the code to see how stronger or weaker gravity affects the system.

2. **Inelastic Collisions**  
   Modify the collision formulas to remove some fraction of velocity (e.g., multiply velocities by 0.9) to simulate energy loss.

3. **Friction / Damping**  
   Multiply each velocity by a factor < 1 (e.g., 0.99) each tick to simulate drag or friction.

4. **Remove Gravity**  
   Comment out the `apply-gravity` procedure call so turtles only collide with each other and the walls.

5. **Increase Turtles**  
   Raise the number of turtles to see if performance changes or how collisions become more frequent.

---

## EXTENDING THE MODEL

- **Rotational Dynamics**: Give turtles angular velocity and calculate spin changes on collisions.  
- **Gravitational Attraction**: Replace the constant downward gravity with pairwise Newtonian attraction so turtles orbit each other.  
- **Spatial Partitioning**: For many turtles (hundreds or thousands), collision checks become expensive. Implement a grid or quadtree to reduce the computational load.  


---

## NETLOGO FEATURES

- **Turtles**: Each turtle holds custom variables (`vx`, `vy`, `mass`, `radius`).  
- **Patches**: Used here primarily for setting a background color.  
- **Built-In Primitives**:  
  - `distance` for measuring the distance between turtles,  
  - `min-pxcor` / `max-pxcor` (and similarly `pycor`) for boundary detection.  
- **Procedures**: The model splits actions into distinct procedures (`apply-gravity`, `move-turtles`, `handle-wall-collisions`, `handle-turtle-collisions`).

---

## RELATED MODELS

- **GasLab** models in the NetLogo Models Library, which simulate elastic collisions among particles in a 2D container.  
- **Particle System** or other physical simulation models available in the library or on the NetLogo community website.

---

## CREDITS AND REFERENCES

- This code and explanation were adapted for demonstration purposes.  
- NetLogo is created by Uri Wilensky and developed at the Center for Connected Learning and Computer-Based Modeling, Northwestern University.  
- To learn more about NetLogo, visit the [NetLogo website](https://ccl.northwestern.edu/netlogo/).
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
