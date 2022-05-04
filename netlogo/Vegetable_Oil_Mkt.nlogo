globals [ ;variaveis globais
  ticket_counter;                      # contador de tickets
  ticket_counter_limit;

  price_palm
  price_palm_kernel
  price_rapeseed
  price_soybean
  price_sunflower
]

breed [ commodities commodity];         # Define a especie/raca de commodities
breed [ axies axie ];                   # Define os eixos X e Y
breed [ curves curve ];                 # Define as curvas de oferta e demanda


commodities-own [
  quantity;                             # quantidade/volume em ktons do equilibrio
  price;                                # preco em USD/Ktons do equilibrio
  bearish;                              # comportamento em bearish 'Queda'
  bullish;                              # comportamento em bulish 'subida'
  pression;                             # p<-1 é descida, p>1 é subida e -1<p<1 é sidewalk
  commodity_type;                       # tipo de commodity
  strategy;
]

curves-own [
  intercept;                            # intercepto da curva
  coef;                                 # coeficiente da curva
  err;                                  # fator de erro
]


to setup
  ;#########################################
  ; Configuracao
  ;#########################################
  clear-all;                                     # limpa o mundo
  clear-output;                                  # limpa o command center
;  random-seed 45;                                # para sempre gerar a mesma amostragem
  set ticket_counter_limit 1000;                 # define o limite do counter, para condicao de stop

  create_agents
  reset-ticks ;reset time/simulation
end; setup


to go
  ; 1 tick = 1 day
  if ( ticket_counter >= ticket_counter_limit ) [stop]

;  ask tutles[
;    if commodity_type = ""
;  ]


  tick;                                     # tick
  set ticket_counter ticket_counter + 1;    # incremento do counter
  print ticket_counter
end; go


to create_agents

  create-commodities 1 [
    set shape "acorn"
    set color green
    set xcor -12
    set ycor 12
    set commodity_type "Palm"
  ]

  create-commodities 1 [
    set shape "palm-kernel"
    set color orange + 2
    set xcor -12
    set ycor 0
    set commodity_type "Palm-Kernel"
  ]

  create-commodities 1 [
    set shape "rapeseed"
    set color yellow
    set xcor 12
    set ycor 12
    set commodity_type "Rapeseed"
  ]

  create-commodities 1 [
    set shape "plant";
    set color green;
    set xcor 12;
    set ycor 0;
    set commodity_type "Soybean";
    set strategy strategy_two;
  ]


  create-commodities 1 [
    set shape "flower"
    set color yellow
    set xcor 12
    set ycor -12
    set commodity_type "Sunflower"
    set strategy strategy_one
  ]

  ask commodities[
    set size 6
    set label commodity_type
    set pression get_pression
  ]

  create-axies 1[; Eixo y | Preco
    set heading 0;
  ]

  create-axies 1[; Eixo x | Quantidade
    set heading 90;
  ]

  ask axies [
    set color white;
    set xcor -8;
    set ycor -8;
    set pen-mode "down";
    set pen-size 2;
    forward 18;
  ]

  create-curves 1[; Demanda
    set xcor -8;
    set ycor -8;
  ]

  create-curves 1[; Oferta

  ]

  ask curves[
    set color yellow;
    set pen-mode "down";
    set pen-size 2;
    set shape "dot"
  ]

;
;  ;#########################################
;  ;Paper Producers (Customers)
;  ;#########################################
;  create-ordered-major_customers number_of_major_customers [
;    forward 8
;    facexy 0 0
;    set color 107
;    set size 5
;    set shape "circle"
;    ifelse major_customers_margins = "High" [set market_pressure market_pressure + (15 / number_of_major_customers) ] [
;      ifelse major_customers_margins = "Healthy" [set market_pressure market_pressure - 0] [ set market_pressure market_pressure - (15 / number_of_major_customers)]
;    ]
;  ]



end


to scenery_one
  ;#########################################
  ; Quantidades de cada commodity do Cenario 1
  ;#########################################
  set qty_palm            50
  set qty_palm_kernel     20
  set qty_rapeseed        10
  set qty_soybean         (35)
  set qty_sunflower       (10)
end; scenery_one


to-report tot_supply []; Funcao que retorna o total volume de commodities
  report qty_sunflower + qty_soybean + qty_palm + qty_palm_kernel + qty_rapeseed
end;

to-report tot_demand []; Funcao que retorna o total de demanda commodities. Tentei fazer o incremento de 4% ao ano.
  report tot_supply +  (ticket_counter / 365) * 0.04 * tot_supply;  tot_supply * (ticket_counter - 1) * 0.04 / tot_supply
end;

to-report get_pression[]; Funcao que gera um randomico para [-2, -1, 0, 1, 2]
 report random 5 - 2;
end

to-report strategy_one[];
  report 200 + qty_soybean
end

to-report strategy_two[];
  report 500 + qty_sunflower
end

to-report xy_draw [];
  ;#########################################
  ; Funcao que retorna o total volume de commodities
  ;#########################################

  report qty_sunflower + qty_soybean + qty_palm + qty_palm_kernel + qty_rapeseed
end;
@#$#@#$#@
GRAPHICS-WINDOW
340
10
623
294
-1
-1
8.34
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
45
32
116
65
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
131
31
218
65
Scenery 1
scenery_one
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
30
130
63
390
qty_palm
qty_palm
0
100
50.0
.5
1
Year Ktons
VERTICAL

SLIDER
70
130
103
390
qty_palm_kernel
qty_palm_kernel
0
100
20.0
.5
1
Year Ktons
VERTICAL

SLIDER
110
130
143
390
qty_soybean
qty_soybean
0
100
35.0
.5
1
Year Ktons
VERTICAL

SLIDER
150
130
183
390
qty_sunflower
qty_sunflower
0
100
10.0
.5
1
Year Ktons
VERTICAL

SLIDER
190
130
223
390
qty_rapeseed
qty_rapeseed
0
100
62.5
.5
1
Year Ktons
VERTICAL

MONITOR
635
5
815
66
Vegetable total supply
tot_supply
4
1
15

BUTTON
240
80
330
113
Run Model
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

PLOT
463
301
698
474
Demand & Supply
Quantity
Price
0.0
100.0
0.0
500.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plotxy total_commodity"
"Total" 1.0 0 -7500403 true "" "plot tot_supply"

BUTTON
240
10
330
43
Run once
go
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
240
45
330
78
Run slowly
every 0.5 [go]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
246
316
446
466
Quantity
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"supply" 1.0 0 -16777216 true "" "plot tot_supply"
"demand" 1.0 0 -2674135 true "" "plot tot_demand"

PLOT
639
123
839
273
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"
"pen-1" 1.0 0 -7500403 true "" "plot get_pression"

MONITOR
634
74
719
119
NIL
get_pression
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

acorn
false
0
Polygon -7500403 true true 146 297 120 285 105 270 75 225 60 180 60 150 75 105 225 105 240 150 240 180 225 225 195 270 180 285 155 297
Polygon -6459832 true false 121 15 136 58 94 53 68 65 46 90 46 105 75 115 234 117 256 105 256 90 239 68 209 57 157 59 136 8
Circle -16777216 false false 223 95 18
Circle -16777216 false false 219 77 18
Circle -16777216 false false 205 88 18
Line -16777216 false 214 68 223 71
Line -16777216 false 223 72 225 78
Line -16777216 false 212 88 207 82
Line -16777216 false 206 82 195 82
Line -16777216 false 197 114 201 107
Line -16777216 false 201 106 193 97
Line -16777216 false 198 66 189 60
Line -16777216 false 176 87 180 80
Line -16777216 false 157 105 161 98
Line -16777216 false 158 65 150 56
Line -16777216 false 180 79 172 70
Line -16777216 false 193 73 197 66
Line -16777216 false 237 82 252 84
Line -16777216 false 249 86 253 97
Line -16777216 false 240 104 252 96

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

palm-kernel
false
2
Polygon -955883 true true 146 297 120 285 105 270 75 225 60 180 60 150 75 105 225 105 240 150 240 180 225 225 195 270 180 285 155 297
Polygon -6459832 true false 121 15 136 58 94 53 68 65 46 90 46 105 75 115 234 117 256 105 256 90 239 68 209 57 157 59 136 8
Circle -16777216 false false 223 95 18
Circle -16777216 false false 219 77 18
Circle -16777216 false false 205 88 18
Line -16777216 false 214 68 223 71
Line -16777216 false 223 72 225 78
Line -16777216 false 212 88 207 82
Line -16777216 false 206 82 195 82
Line -16777216 false 197 114 201 107
Line -16777216 false 201 106 193 97
Line -16777216 false 198 66 189 60
Line -16777216 false 176 87 180 80
Line -16777216 false 157 105 161 98
Line -16777216 false 158 65 150 56
Line -16777216 false 180 79 172 70
Line -16777216 false 193 73 197 66
Line -16777216 false 237 82 252 84
Line -16777216 false 249 86 253 97
Line -16777216 false 240 104 252 96
Circle -5825686 true false 90 120 120
Circle -1 true false 96 126 108

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

rapeseed
false
4
Polygon -7500403 true false 135 300 135 195 120 195 94 201 81 183 75 171 74 95 79 79 88 74 90 75 90 90 90 150 105 195 120 180 135 165 135 30 135 30 145 16 150 30 150 30 150 165 180 165 195 150 195 135 195 120 195 120 199 103 212 108 215 121 215 144 210 165 196 177 176 181 150 180 159 302
Line -16777216 false 142 32 146 143
Line -16777216 false 123 191 114 197
Line -16777216 false 113 199 96 188
Line -16777216 false 95 188 84 168
Line -16777216 false 83 168 82 103
Line -16777216 false 201 147 202 123
Line -16777216 false 190 162 199 148
Line -16777216 false 174 164 189 163
Polygon -1184463 true true 210 135 225 90 195 60 195 90
Polygon -1184463 true true 195 180 255 150 240 135
Polygon -1184463 true true 165 75 165 75 195 30 195 0 180 30
Polygon -1184463 true true 135 75 135 75 120 0 75 15
Polygon -1184463 true true 90 135 120 75 90 60
Polygon -1184463 true true 75 150 45 90 60 45
Polygon -1184463 true true 90 180 30 135 45 180
Polygon -1184463 true true 150 105 180 60 180 30
Polygon -1184463 true true 90 195 120 150 105 120 105 135
Polygon -1184463 true true 180 165 180 165 165 120 180 75
Polygon -1184463 true true 180 180 165 195 225 225

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
NetLogo 6.2.2
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
