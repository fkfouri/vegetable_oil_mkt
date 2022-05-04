;; Bulls & Bears
;; A Minimalist Artificial Stock Market
;; http://ccl.northwestern.edu/netlogo/models/community/Bulls%20and%20Bears

globals [
;; From sliders:
;; investors                         ;; total number of investors/agents
;; fraction-contrarians              ;; percentage of investors that are contrarians
;; memory                            ;; number of periods m that price is remembered
;; wealth-factor                     ;; coefficient k1
;; maximum-herd-effect-followers     ;; coefficient k2
;; maximum-herd-effect-contrarians   ;; coefficient k3
;; maximum-risk-appetite             ;; coefficient k4
;; price-sensitivity-to-demand       ;; coefficient k5

;; Others:
  num-contrarians                    ;; total number of contrarians
  num-followers                      ;; total number of followers
  risk-appetite-big                  ;; used for ma >=0
  risk-appetite-small                ;; used for ma < 0
  tot-demand-followers               ;; total demand of followers
  tot-demand-contrarians             ;; total demand of contrarians
  tot-demand                         ;; total value of shares demanded
;;  tot-share-demand                   ;; total number of shares demanded
  price                              ;; current calculated price
  last-price                         ;; price at time t-1
  return                             ;; percentage price change from t-1 to t
  value-traded                       ;; equal to smaller of demands, to clear market
  volume-traded                      ;; value traded divided by share price
  followers-wealth                   ;; total wealth of followers
  contrarians-wealth                 ;; total wealth of contrarians
  total-wealth                       ;; total wealth of all investors
  max-wealth                         ;; highest wealth of all investors
  min-wealth                         ;; lowest wealth of all investors
  max-demand-c                       ;; maximum demand of contrarians
  max-demand-f                       ;; maximum demand of followers
  max-demand                         ;; highest demand of all investors
  min-demand                         ;; lowest demand of all investors
  all-return-list                    ;; collects all returns
  return-list                        ;; collects last m returns
  moving-average                     ;; average return over last m periods
  all-volatility-list                ;; collects all volatilities
  volatility-price-list              ;; collects last 36 prices
  volatility                         ;; standard deviation of returns over last 36 periods
  value-traded-list                  ;; collects values traded
  volume-traded-list                 ;; collects volumes traded
  graph-max                          ;; maximum of previous two lists
  graph-min                          ;; minimum of previous two lists
  ]

turtles-own
[
  follower
  contrarian
  cash
  shares-value
  shares
  wealth
  wealth-effect                     ;; part of investors' demand function
  herd-effect-follower              ;; part of followers' demand function
  herd-effect-contrarian            ;; part of contrarians' demand function
  risk-appetite                     ;; part of investors' demand function
  demand-follower
  demand-contrarian
  shares-value-transacted
]

to setup
  ca
  random-seed 1051100757  ;; if required
  ask patches [ set pcolor white ]  ;; create a blank background
  create-turtles investors [ setxy random-xcor random-ycor set size 3 ]

;; Create empty lists for return histogram, moving average of last m returns, 36-period price volatility, trade
  set all-return-list [ 0 ]  ;; for histogram scaling
  set return-list []  ;; for moving average
  while [ length return-list < memory ] [ set return-list lput 0 return-list ]
  set all-volatility-list [ 0 0.2]  ;; for volatility graph scaling
  set volatility-price-list []
  while [ length volatility-price-list < 36 ] [ set volatility-price-list lput 100 volatility-price-list ]
  set value-traded-list []  ;; for trade graph scaling
  set volume-traded-list []  ;; for trade graph scaling

 set num-contrarians round ( ( fraction-contrarians ) / ( 100 ) * ( investors ) )
 set num-followers ( investors - num-contrarians )

;; Initialise some variables
  set price ( 100 )
  set moving-average ( 0 )
  set graph-min ( 0 )
  set graph-max ( 1 )

;; Divide into two investor types
ask turtles
  [
   set cash 50
   set shares-value 50
   set wealth  cash + shares-value

   ifelse who < num-contrarians
      [
        set contrarian 1
        set follower 0
        set shape "wolf 3"
        set color red
      ]
      [
        set contrarian 0
        set follower 1
        set shape "cow skull"
        set color blue
      ]
  ]
  reset-ticks
end

to go
;; For each investor calculate *magnitudes* of demands, i.e. "desired size of bet"
  set risk-appetite-big maximum-risk-appetite / 1 * moving-average
  set risk-appetite-small maximum-risk-appetite / 2.5 * moving-average  ;; investors hate losses ~2.5 times as much as they love gains

  ask turtles
      [
        ;; Wealth: range of wealth parameter (i.e. on slider) and other parameters need to be determined empirically
        set wealth-effect ( ( wealth-factor ) * ( wealth ) )  ;; this is per investor

        ifelse contrarian = 1
        [
          ;; Herding: the susceptibility of investors to herding by their own type ranges randomly from zero to the maximum
          set herd-effect-contrarian random-float abs ( ( maximum-herd-effect-contrarians ) * ( tot-demand-contrarians ) / ( num-contrarians ) )  ;; normalize per investor
          ;; Risk appetite:
            ifelse moving-average >= 0
              [ set risk-appetite random-float risk-appetite-small ]
              [ set risk-appetite random-float ( - ( risk-appetite-big ) ) ]  ;; this is per investor
          set demand-contrarian max list 0 ( wealth-effect + herd-effect-contrarian  +  risk-appetite )
          ;; Full demand function: is "desired size of bet" so cannot be less than zero; the sign is then determined purely by type of investor
          set demand-contrarian min list demand-contrarian wealth  ;; Can't bet more than one's wealth
          ;; Scaling for main graph
          if ticks > 2 [set color scale-color blue risk-appetite ( max [ risk-appetite ] of turtles + 1 ) ( min [ risk-appetite ] of turtles) ]  ;; + 1 is error trap for when m.a. = 0
          set size min list ( 0.5 * herd-effect-contrarian + 1.3 ) 7
        ]
        [
          set herd-effect-follower random-float abs ( ( maximum-herd-effect-followers ) * ( tot-demand-followers ) / ( num-followers) )
           ifelse moving-average >= 0
             [ set risk-appetite random-float ( - ( risk-appetite-big ) ) ]
             [ set risk-appetite random-float risk-appetite-small ]
          set demand-follower max list 0 ( wealth-effect + herd-effect-follower + risk-appetite )
          set demand-follower min list demand-follower wealth
          if ticks > 2 [ set color scale-color red risk-appetite ( max [ risk-appetite ] of turtles + 1 ) ( min [ risk-appetite ] of turtles ) ]
          set size min list ( 0.5 * herd-effect-follower + 1.3 ) 7
        ]
    ]
;; In the risk appetite calculation above it is assumed that if e.g. moving-average >= 0 followers would have largely been long, so their
;; risk appetite will be big, with the converse for contrarians. Ideally, each investor should have their own personal moving-average.

;;  For each investor type, aggregate demand
        set tot-demand-followers sum [ demand-follower ] of turtles
          if  tot-demand-followers = 0 [ set tot-demand-followers (10) ]  ;; error trap for division by zero
        set tot-demand-contrarians sum [ demand-contrarian ] of turtles
          if  tot-demand-contrarians = 0 [ set tot-demand-contrarians (10) ]  ;; error trap for division by zero

;;  For each investor type now calculate *sign* of aggregate demand, i.e. direction of aggregate bet
      ifelse return > 0
        [ set tot-demand-contrarians (- tot-demand-contrarians) ]
        [ set tot-demand-followers (- tot-demand-followers) ]

   set tot-demand ( tot-demand-followers ) + ( tot-demand-contrarians )  ;; i.e. is *net* demand

;; Calculate new price
  set last-price price
  set price ( ( last-price ) + ( price-sensitivity-to-demand ) * ( tot-demand ) )
  if price <= 0 [set price (1)]  ;; error trap - price floor

;; Calculate return over period
  set return ( ( price ) / ( last-price ) - ( 1 ) ) * ( 100 )

;; Add return to the all-return list, then the moving-average return list and take average of this list
  set all-return-list lput return all-return-list
  set return-list lput return return-list
  set return-list remove-item 0 return-list
  set moving-average ( mean return-list )

;; Add price to the volatility price list, take standard deviation of list, cumulate volatilities
  set volatility-price-list lput price volatility-price-list
  set volatility-price-list remove-item 0 volatility-price-list
  set volatility ( standard-deviation volatility-price-list )
  if ticks > 36 [ set all-volatility-list lput volatility all-volatility-list ]  ;; start to cumulate volatilities when past initialized dummy data

;; Calculate value traded (equal to smaller of demands, to clear market) and volume
  set value-traded min list abs tot-demand-followers abs tot-demand-contrarians
  set volume-traded ( value-traded ) / ( price ) * ( 100 )

;; For trade graph scaling
  set value-traded-list lput value-traded value-traded-list
  set volume-traded-list lput volume-traded volume-traded-list
  set graph-max max list ( max value-traded-list ) ( max volume-traded-list )
  set graph-min min list ( min value-traded-list ) ( min volume-traded-list )

;; Recalculate investors' wealth
  ask turtles
    [
      ifelse contrarian = 1
      [  set shares-value-transacted ( demand-contrarian ) / ( tot-demand-contrarians ) * ( value-traded )  ;; get share value allocated pro-rata to relative demand
        ;; change investors' cash and share balances
           ifelse return >= 0
        [
          set shares-value shares-value - shares-value-transacted
          set shares ( shares-value ) / ( last-price )
          set cash cash + shares-value-transacted
        ]
        [
          set shares-value shares-value + shares-value-transacted
          set shares ( shares-value ) / ( last-price )
          set cash cash - shares-value-transacted
        ]
      ]
      [  set shares-value-transacted ( demand-follower ) / ( tot-demand-followers ) * ( value-traded )
           ifelse return >= 0
        [
          set shares-value shares-value + shares-value-transacted
          set shares ( shares-value ) / ( last-price )
          set cash cash - shares-value-transacted
        ]
        [
          set shares-value shares-value - shares-value-transacted
          set shares ( shares-value ) / ( last-price )
          set cash cash + shares-value-transacted
        ]
       ]
        set wealth ( shares ) * ( price ) + ( cash )  ;; update investors' wealth
    ]

  ;; Scaling of main graph
  set followers-wealth sum [ wealth ] of turtles with [ follower = 1 ]
  set contrarians-wealth sum [ wealth ] of turtles with [ contrarian = 1 ]
  set total-wealth sum [ wealth ] of turtles
  set max-wealth max [ wealth] of turtles
  set min-wealth min [ wealth] of turtles
  if max-wealth = min-wealth [ set max-wealth ( max-wealth + random ( 10 ) )  set min-wealth ( min-wealth - random ( 10 ) ) ]  ;; error trap to stop division by zero in plot
  set max-demand-c max [ demand-contrarian ] of turtles
  set max-demand-f max [ demand-follower ] of turtles
  set max-demand max list max-demand-c max-demand-f   ;; must be a cleverer way to do this
  set min-demand min list min [ demand-contrarian ] of turtles min [ demand-follower ] of turtles

ask turtles
;;  [ if wealth >= 0
    [
     ifelse contrarian = 1
      [ setxy ((( wealth - min-wealth ) / ( max-wealth - min-wealth ) * ( max-pxcor - min-pxcor)) + min-pxcor ) ((( demand-contrarian - min-demand ) / ( max-demand - min-demand ) * ( max-pycor - min-pycor)) + min-pycor ) ]
      [ setxy ((( wealth - min-wealth ) * ( max-pxcor - min-pxcor) / ( max-wealth - min-wealth )) + min-pxcor ) ((( demand-follower - min-demand ) / ( max-demand - min-demand ) * ( max-pycor - min-pycor)) + min-pycor ) ]
;;    ]
  ]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
10
183
419
593
-1
-1
7.04
1
8
1
1
1
0
0
0
1
-28
28
-28
28
1
1
1
Time periods
30.0

BUTTON
54
115
124
149
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
134
115
206
150
go once
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

SLIDER
6
12
214
45
Investors
Investors
10
200
10.0
10
1
(no.)
HORIZONTAL

SLIDER
4
48
213
81
Fraction-contrarians
Fraction-contrarians
0
100
50.0
1
1
(%)
HORIZONTAL

SLIDER
217
14
422
47
Memory
Memory
2
12
9.0
1
1
(periods)
HORIZONTAL

SLIDER
217
50
423
83
Wealth-factor
Wealth-factor
0.01
.05
0.03
.01
1
(k1)
HORIZONTAL

SLIDER
429
12
669
45
Maximum-herd-effect-followers
Maximum-herd-effect-followers
.5
2.5
1.25
.05
1
(k2)
HORIZONTAL

SLIDER
429
49
668
82
Maximum-herd-effect-contrarians
Maximum-herd-effect-contrarians
.5
2.5
1.25
.05
1
(k3)
HORIZONTAL

SLIDER
671
14
892
47
Maximum-risk-appetite
Maximum-risk-appetite
1
20
10.0
1
1
(k4)
HORIZONTAL

SLIDER
674
50
894
83
Price-sensitivity-to-demand
Price-sensitivity-to-demand
.001
.007
0.004
.001
1
(k5)
HORIZONTAL

PLOT
435
220
667
340
Demand
Time
Value ($)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Followers" 1.0 2 -2674135 true "" "plot tot-demand-followers"
"Contrarians" 1.0 2 -13345367 true "" "plot tot-demand-contrarians"
"Total" 1.0 1 -16777216 true "" "plot tot-demand"
"axis" 1.0 0 -16777216 false "" "auto-plot-off\nplotxy 0 0\nplotxy 1000000000 0\nauto-plot-on"

PLOT
434
95
894
215
Share price
Time
Price ($)
0.0
10.0
100.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot price"

PLOT
671
220
893
340
Period return & MA
Time
(%)
0.0
10.0
-1.0
1.0
true
false
"" ""
PENS
"Return" 1.0 1 -16777216 false "" "plot return"
"MA" 1.0 0 -2674135 true "" "plot moving-average"
"axis" 1.0 0 -16777216 false "" "auto-plot-off\nplotxy 0 0\nplotxy 1000000000 0\nauto-plot-on"

PLOT
435
472
666
592
Trade
Time
($ ,shares)
0.0
10.0
0.0
10.0
true
true
"" "set-plot-y-range (round graph-min - 1) (round graph-max + 1)"
PENS
"Value" 1.0 0 -2674135 true "" "plot value-traded"
"Volume" 1.0 0 -13345367 true "" "plot volume-traded"

PLOT
435
345
665
465
Returns distribution
Period return (%)
Freq (no.)
0.0
1.0
0.0
1.0
true
false
"set-histogram-num-bars 9\n" "set-plot-y-range 0 1\nset-plot-x-range round (min all-return-list - 1) round (max all-return-list + 1)"
PENS
"returns" 1.0 1 -16777216 false "" "histogram all-return-list"

PLOT
672
473
892
593
Wealth
Time
Wealth ($)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Followers" 1.0 0 -2674135 true "" "if ticks > 1 [ plot followers-wealth ]"
"Contrarians" 1.0 0 -13345367 true "" "if ticks > 1 [ plot contrarians-wealth ]"
"Total" 1.0 0 -16777216 true "" "if ticks > 1 [ plot total-wealth ]"

TEXTBOX
11
161
136
179
Demand ($)
12
0.0
1

TEXTBOX
194
597
319
615
Wealth ($)
12
0.0
1

BUTTON
215
115
296
150
go slowly
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
672
345
893
465
Price volatility (36-period)
Time
 (%)
0.0
10.0
0.0
1.0
true
false
"" "plot-pen-up\nif ticks > 36 [ plot-pen-down set-plot-y-range round precision (min all-volatility-list) 1 round precision (max all-volatility-list) 1 + 0.5]"
PENS
"volatility" 1.0 0 -16777216 false "" "plot volatility"

TEXTBOX
15
187
184
252
Investors:\nShape and color = investor type\nSize = susceptibility to herd effect\nColor intensity = risk appetite
10
0.0
0

TEXTBOX
50
90
385
116
Note that under many combinations of input parameters a stock market as modeled will become unstable. These are legitimate phenomena as discussed in the Info tab and not code flaws.
7
0.0
1

BUTTON
304
115
368
149
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

MONITOR
945
55
1027
100
NIL
all-return-list
17
1
11

MONITOR
945
105
1185
150
NIL
return-list
17
1
11

MONITOR
945
155
1037
200
NIL
all-volatility-list
17
1
11

MONITOR
945
210
1045
255
NIL
num-contrarians
17
1
11

MONITOR
945
265
1185
310
NIL
volume-traded-list
17
1
11

MONITOR
1055
210
1142
255
NIL
num-followers
17
1
11

MONITOR
950
320
1052
365
NIL
risk-appetite-big
17
1
11

MONITOR
950
375
1207
420
NIL
maximum-risk-appetite / 1 * moving-average
17
1
11

@#$#@#$#@
# BULLS & BEARS - A MINIMALIST ARTIFICIAL STOCK MARKET
## WHAT IS IT?

The model explores the mechanism of price formation in a stock market. The model is relatively simple, yet generates all the emergent properties of real stock markets. It also shows under what circumstances one can get pathological price behaviour such as monotonic moves to zero or infinity, or permanent oscillations between two price levels.

## THE MODEL

There is one asset (a stock) in the market. The model is non-spatial. Agents (investors) do not interact with each other directly but with the stock price, which is determined by the total demand for the stock, i.e., they interact indirectly in their aggregate. So net aggregate demand determines the price movement in each time period (tick), and this price movement then determines the investors' demand in the next time period. The price formation mechanism is thus highly recursive.

### Investor types

There is a variable number of investors. These investors are of two types, followers and contrarians, with two diametrically opposite strategies. If the stock’s price moved up in the last time period, followers want to buy while contrarians wish to sell, and vice versa for a downward move in price. There are therefore always buyers and sellers, but with differing demands of the quantity desired to transact. There is no leverage, but short selling is allowed. 

Sales of the stock generate cash for an investor and purchases require cash. An investor's wealth is the sum of the value of their shareholding and their cash balance.

### Demand function 
In every time period there will be demand from both followers and contrarians. The magnitude of their demand represents "how big do I want to bet" and is determined by a demand function. It is always a positive number or zero. The sign of this demand, i.e. buy or sell, is then determined separately by the previous price move.

For each investor, their demand function contains three components:

**Risk demand.**
The value of stock demanded is proportional to the moving average (m.a.) of returns over the last _m_ returns. (Investors have a memory of the last _m_ time periods.)
So risk demand = (_k_<sub>4</sub>) (_r_) (_s_) (m.a.) where:
_k_<sub>4</sub> is an empirical constant,
_r_ is a scale factor: _r_ = 1 if m.a. >=0 and _r_ = 2.5 if m.a. <0, since studies have shown that investors hate losses ~2.5x more than they love gains. 
_s_ is the sign. If the m.a. is positive, investors know there is a a higher probability of future negative returns, so the risk appetite of contrarians will increase and that of followers will decrease. So if m.a. is +/-, the sign for contrarians will be +/- and for followers will be -/+. 

The value of the risk demand is the same for all investors in one time period. Individual investors are then randomly assigned an individual risk demand in the range [0, risk demand].

**Herd demand.**
The value of stock demanded is proportional to the aggregate stock demanded by other investors _of the same type_. It is assumed that followers and contrarians have different propensities to herd, and are given two different empirical constants.

So herd demand = (_k_<sub>2</sub>) (total demand of followers) for followers, and
... herd demand = - (_k_<sub>3</sub>) (total demand of contrarians) for contrarians
Note that the herd demand can only be of positive sign.

This value of herd demand is therefore different for each type of investor in a time period. Individual investors of each type, i.e. followers and contrarians, are then randomly assigned an individual herd demand in the range [0, herd demand - followers] and [0, herd demand - contrarians] respectively.

**Wealth demand.**
The value of stock demanded is proportional to the investor's wealth.
So wealth demand = (_k_<sub>1</sub>) (wealth), where _k_<sub>1</sub> is an empirical constant.

This demand component is the same for all investors. Note "wealth demand" will be of the same sign as wealth, which we assume can be negative as well as positive. This value of wealth demand is the same for all investors in one time period. Individual investors are then randomly assigned an individual wealth demand in the range [0, wealth demand].

Investors' wealth is dependent on how many shares they buy or sell in each time period. The value of their shares will then change with the new share price in the next period, in turn changing their wealth.

The total demand for each investor is then the sum of these three demands. Its sign must always be positive as it is the "size of desired bet", and its sign will simply be determined by the direction of the previous price move. Therefore, if the magnitude of total demand is less than zero, it is set to zero.

### Price, price return, value and volume traded
The net share value demanded is
_D_ = (demand from followers + demand from contrarians)
where the two demands are appropriately signed.

The change in stock price is then proportional to this net demand. So, at time _t_ the price is
_P_<sub>_t_</sub> = _P_<sub>_t_-1</sub> + (_k_<sub>5</sub>) (_D_) where _k_<sub>5</sub> is an empirical constant.

Note that changing the number of investors is not neutral - a larger number of investors will tend to result in larger net demands _D_, which will cause larger price changes.

The stock price return will be
_R_<sub>_t_</sub> = (_P_<sub>t-1</sub> / _P_<sub>t</sub>) - 1 (log returns are not strictly necessary here).

Followers and contrarians will usually wish to transact with different amounts of demand, so to clear the market the total share value traded is
_T_<sub>_t_</sub> = _min_ (|demand from followers|, |demand from contrarians|)

Note that all the model's relationships are linear, while in the real world everything is non-linear!

## HOW TO USE IT

The input items in the interface tab are largely self-explanatory, consisting of the number of investors, the fraction of investors who are contrarians, the persistence of investors' memory (_m_ time periods) and the empirical parameters _k_<sub>1</sub>..._k_<sub>5</sub>.
The command buttons are the usual ones. "Go once" is useful for examining the causes of a price change from tick to tick and for debugging. The _"go slowly"_ button uses one tick every 0.5 seconds, to slow things down.

## OUTPUTS

The prime output is the share price graph. The value of stock demanded (in dollars) by followers and contrarians, and their total, is also shown. The next plot shows the percentage return in each period, together with the moving average of the previous _m_ periods, i.e. it shows if the share has generally gone up or down in investors' recent memory, and by how much. The distribution of these returns is also shown. Market returns are not random and their distribution is not normal. The volatility of price movements over the past 36 periods is calculated and displayed. Trade, in both dollars and number of shares, is also plotted, as is the dollar wealth of followers, contrarians and their total. The Demand/Wealth graph is discussed in NETLOGO FEATURES.

This data can then be extracted with BehaviorSpace and analysed to see if it accords with the known emergent phenomena of markets, which include:

  * persistence of returns
  * volatility clustering
  * low autocorrelation
  * excess kurtosis
  * volume correlation with price volatility

## THINGS TO NOTICE

A market consisting of only these two types of investors is intrinsically unstable. This is exacerbated by the fact that as an investor's wealth grows, they take larger buying or selling positions.

There are two bounding unstable price behaviors:
  * If the demand of followers is greater than contrarians (e.g., there are no contrarians) and the price, for example, declines, then it will continue declining to zero. Conversely if the price moves up it will continue to infinity.
  * If the demand of contrarians is greater than that of followers, for either initial price movement, the price subsequently will become cyclical, oscillating indefinitely between two values. 

Most combinations of parameter settings eventually lead to these bounding behaviors.

Also, in the case of monotonic increases or decreases in price, the wealth of followers will become infinite, while price oscillations will see the wealth of contrarians rise to infinity, as these investors will make the correct decision in every time period. 

These behaviors are legitimate and would happen in a real market as modeled. They are not a code flaw. They demonstrate the intrinsic instability of markets. Market crashes, for example, often occur without any obvious proximate cause - they are simply emergent behavior. (And, inevitably, if the price goes to zero, many variables tend to blow up.) 

## THINGS TO TRY

Best explored with the _"go once"_ or _"go slowly"_ buttons. Try adjusting the parameters under various settings. How sensitive is the stability of price behavior to these parameters? Which parameters counteract each other and which reinforce each other? If there are exactly equal numbers of followers and contrarians, what does the stock price do? See the extreme situations where there are only followers or contrarians, which breaks the market. Do the returns look random or is there clustering? Can you see fat tails and kurtosis in the return distributions? Does the price volatility correlate with anything?

## EXTENDING THE MODEL

Possible embellishments of the model are limitless. Additional investor categories such as long-term and short-term players and insider traders could be added. Individual investors could be allowed to use leverage. Also, risk appetite (as determined by the moving average) has been the same for each investor type. Ideally, each investor should use the moving average of their individual return history. Additional assets, as well as transaction costs could be incorporated. Most importantly, investors could be given a range of different and possibly competing strategies, including adaptive ones - which is closest to the actual behaviour in real markets. (This was the original Santa Fe Artificial Stock Market Model.)
Note that complicating the model does not change the market's emergent properties materially. It can however be useful in examining the sensitivity to these additional parameters.

## NETLOGO FEATURES

Because the model is non-spatial, the main plot has been transformed into a graph. This graph shows 5 dimensions for each agent on the same plot using shape, coordinates, size and color intensity to indicate agent type, wealth, demand, herd influence and risk aversion, respectively.

The histogram is of a global variable, not a turtle property. In this case, 'histogram' operates on a list. So the variable's values were accumulated in a list, with the list being extended by one element at each tick. Lists were also required to accumulate histories for the moving average of the last _m_ returns and 36-period price volatility.

They were also used for the dynamic scaling of some graphs. Smart scaling is implemented on the 'Returns distribution', 'Price volatility' and 'Trade' graphs via plot update commands.

A zero axis is drawn on the Demand and Period return & MA graphs. The Price volatility graph only begins drawing after 36 periods, using the plot-pen-up command in the plot update commands. 

## RELATED MODELS

The seminal model in this genre was the original Santa Fe Artificial Stock Market Model:
Arthur, W. B., Holland, J. H., LeBaron, B., Palmer, R., & Taylor, P. (1996). _Asset pricing under endogenous expectation in an artificial stock market._ (No. 96-12-093).

A later retrospection on it was:
LeBaron, B. (2002). _Building the Santa Fe artificial stock market._ Physica A, 1-20.

Various improvements were suggested in the book:
Ehrentreich, N. (2007). _Agent-based modeling: The Santa Fe Institute artificial stock market model revisited._ (Vol. 602). Springer Science & Business Media.

There has been surprisingly little highly-cited research since then. Two studies are:
Šperka, R., & Spišák, M. (2013). _Transaction costs influence on the stability of financial market: agent-based simulation._ Journal of Business Economics and Management, 14(sup1), S1-S12.
Oldham, M. (2017). _Introducing a multi-asset stock market to test the power of investor networks._ Journal of Artificial Societies and Social Simulation, 20(4). 

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:
* Busetti, F. R., (2021).  NetLogo Bulls & Bears model.  http://ccl.northwestern.edu/netlogo/models/BullsBears.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


## COPYRIGHT AND LICENSE

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
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

cow skull
false
0
Polygon -7500403 true true 150 90 75 105 60 150 75 210 105 285 195 285 225 210 240 150 225 105
Polygon -16777216 true false 150 150 90 195 90 150
Polygon -16777216 true false 150 150 210 195 210 150
Polygon -16777216 true false 105 285 135 270 150 285 165 270 195 285
Polygon -7500403 true true 240 150 263 143 278 126 287 102 287 79 280 53 273 38 261 25 246 15 227 8 241 26 253 46 258 68 257 96 246 116 229 126
Polygon -7500403 true true 60 150 37 143 22 126 13 102 13 79 20 53 27 38 39 25 54 15 73 8 59 26 47 46 42 68 43 96 54 116 71 126

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

wolf 3
false
0
Polygon -7500403 true true 105 180 75 180 45 75 45 0 105 45 195 45 255 0 255 75 225 180 195 180 165 300 135 300 105 180 75 180
Polygon -16777216 true false 225 90 210 135 150 90
Polygon -16777216 true false 75 90 90 135 150 90

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>wealth-effect</metric>
    <metric>herd-effect-contrarian</metric>
    <metric>risk-appetite</metric>
    <enumeratedValueSet variable="Maximum-herd-effect-followers">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Investors">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Wealth-effect">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maximum-risk-appetite">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Price-sensitivity-to-demand">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Memory">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Fraction-contrarians">
      <value value="51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maximum-herd-effect-contrarians">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
