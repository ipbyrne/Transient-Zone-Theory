#property indicator_chart_window
#property indicator_buffers 14

input int lookBack = 10000;
input int hleft = 1;
input int hright = 1;
input int k = 50;
input int r = 100;
input bool hidePastPTZs = false; // Hide past PTZ that resolved.
input bool hideTrueTZs = false; // Hide True TZs
input bool factorSpreadRisk = false; // Add spread risk to setup calculations
sinput string Info_1=""; //---------D) OTHER PARAMETERS ---------------------------
input bool drawStats = true; // Draw stats on Chart
input string ObjPrefix="ProberTZv1_";  //Prefix for object names
sinput string InpDirectoryName= "Statistics"; //Folder name
sinput string InpFileName = "ProberTZv1.txt"; //File name
sinput datetime iPeriod_Start=D'2000.01.01 00:00:00'; //Start period for statistics
string objprefix = Symbol() + ObjPrefix;

double TBARS[]; // % of candles thare true transient bars
double PTZR[]; // probability of resolving potential transiet zone
double PTZRF[]; // probability of resolving potential transient zone on form bar
double PTZRFR[];// probability of resolving potential transient zone on form bar within r
double SL[]; // probability of PTZ resolving within r pips.
double RTP[]; // probability of PTZ resolving after breaching r pips.
double URTP[]; // Probability of true transient zone that breachs r while forming
double URNTP[]; // probability of true transient zone not breaching r while forming
double ESL[]; // probability of loss trading away from forming zone
double ETP[]; // probability of gain trading away from forming zone
double EEV[]; // expected value of trading away from forming zone
double CSL[]; // probability of loss trading towards forming zone
double CTP[]; // probability of gain trading towards from forming zone
double CEV[]; // expected value of trading towards forming zone


int highSpreadDist[10000];
int lowSpreadDist[10000];
int highSpreadMax = 0;
int lowSpreadMax = 0;

int rHighSpreadDist[10000];
int rLowSpreadDist[10000];

int urHighSpreadDist[10000];
int urLowSpreadDist[10000];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,TBARS);
   SetIndexBuffer(1,PTZR);
   SetIndexBuffer(2,PTZRF);
   SetIndexBuffer(3,PTZRFR);
   SetIndexBuffer(4,SL);
   SetIndexBuffer(5,RTP);
   SetIndexBuffer(6,URTP);
   SetIndexBuffer(7,URNTP);
   SetIndexBuffer(8,ESL);
   SetIndexBuffer(9,ETP);
   SetIndexBuffer(10,EEV);
   SetIndexBuffer(11,CSL);
   SetIndexBuffer(12,CTP);
   SetIndexBuffer(13,CEV);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){DeleteObjects(objprefix);}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
  int i = lookBack;
  int totalTopPTZs = 0;
  int totalBottomPTZs = 0;
  
  int topResolveonFormBar = 0;
  int bottomResolveonFormBar = 0;
  
  int PTZRFRc = 0;
  
  int totalTopTZs = 0;
  int totalBottomTZs = 0;
  
  bool topPTZCheck = false;
  bool bottomPTZCheck = false;
  int topPTZstartTime = 0;
  int bottomPTZstartTime = 0;
  int highSpread = 0;
  int lowSpread = 0;
  
  double bottomUpZone = 0;
  double topUpZone = 0;
  
  double bottomDownZone = 0;
  double topDownZone = 0;
  while(i>=0)
   {
   //----------------------------------
   // Find Levels to Draw/Calculate PTZ
   //----------------------------------
   // Find highest h-left value
   double highestHLeft = High[iHighest(NULL,0,MODE_HIGH,hleft,i+1)];
   
   // Find lowest h-left value
   double lowestHLeft = Low[iLowest(NULL,0,MODE_LOW,hleft,i+1)];

   //----------------------------------
   // Top PTZ Data Gathering Section - Short Trades
   //----------------------------------
   // Check if high is above highest or low is below lowest
   if(High[i] > highestHLeft && High[i] > (highestHLeft + (k*CalculateNormalizedDigits())) && topPTZCheck == false && bottomPTZCheck == false) // Top PTZ Formed
      {
      // Set Top TZ Y Values
      bottomUpZone = highestHLeft;
      topUpZone = highestHLeft + (k*CalculateNormalizedDigits());
      
      // Count it
      totalTopPTZs++;
      
      // Get & log distance
      int distance = int(MathRound((High[i]-bottomUpZone)/CalculateNormalizedDigits()));
      if(distance > highSpread) {highSpread = distance;}
      if(distance > highSpreadMax) {highSpreadMax = distance;}
      
      // Draw PTZ Rectangle
      string rectName = objprefix + "UTZRECLEFT" + IntegerToString(i);
      //
      ObjectCreate(rectName,OBJ_RECTANGLE,0,Time[i+hleft],topUpZone,Time[i],bottomUpZone);
      
      
      rectName = objprefix + "UTZRECRIGHT" + IntegerToString(i);
      if(i<hright) // Check if rectangle needs to extend past current time
         {
         ObjectCreate(rectName,OBJ_RECTANGLE,0,Time[i],topUpZone,Time[i]+(60*Period() * hright),bottomUpZone);
         }
      else
         {
         ObjectCreate(rectName,OBJ_RECTANGLE,0,Time[i],topUpZone,Time[i-hright],bottomUpZone);
         }
      
      
      // Set Counters to then look for resolve
      topPTZCheck = true;
      topPTZstartTime = i;
      }
   
   // Update Distance
   if(topPTZCheck == true) 
      {
      // Get & log distance
      distance = int(MathRound((High[i]-bottomUpZone)/CalculateNormalizedDigits()));
      if(distance > highSpread) {highSpread = distance;}
      if(distance > highSpreadMax) {highSpreadMax = distance;}
      }
   
   if((topPTZCheck == true && Close[i] < bottomUpZone && i == topPTZstartTime)) // Top PTZ Resolved on bar formed
      {
      topResolveonFormBar++;
      if(highSpread < r) {PTZRFRc++;}
      string dotName = objprefix+"PTZResolveOnFormBar"+IntegerToString(i);
      ObjectCreate(dotName, OBJ_TEXT, 0, Time[i], High[i]); 
      ObjectSetText(dotName, "R", 14, "Arial", Red);
      
      // Color Resolved TZ
      ObjectSet(objprefix + "UTZRECLEFT" + IntegerToString(topPTZstartTime),OBJPROP_COLOR,clrRed);
      ObjectSet(objprefix + "UTZRECRIGHT" + IntegerToString(topPTZstartTime),OBJPROP_COLOR,clrYellow);
      
      // Delete Rectangles
      if(hidePastPTZs)
         {
         ObjectDelete(objprefix + "UTZRECLEFT" + IntegerToString(topPTZstartTime));
         ObjectDelete(objprefix + "UTZRECRIGHT" + IntegerToString(topPTZstartTime));
         }
         
      topPTZCheck = false;
      highSpreadDist[highSpread]++;
      rHighSpreadDist[highSpread]++;
      highSpread = 0;
      i = topPTZstartTime;
      topPTZstartTime = 0;
      }
   
   if((topPTZCheck == true && Low[i] < bottomUpZone && i != topPTZstartTime)) // Top PTZ Resolved after bar formed
      {
      dotName = objprefix+"PTZResolveAfterFormBar"+IntegerToString(i);
      ObjectCreate(dotName, OBJ_TEXT, 0, Time[i], High[i]); 
      ObjectSetText(dotName, "R", 14, "Arial", Green);
      
      // Color Resolved TZ
      ObjectSet(objprefix + "UTZRECLEFT" + IntegerToString(topPTZstartTime),OBJPROP_COLOR,clrRed);
      ObjectSet(objprefix + "UTZRECRIGHT" + IntegerToString(topPTZstartTime),OBJPROP_COLOR,clrYellow);
      
      // Delete Rectangles
      if(hidePastPTZs)
         {
         ObjectDelete(objprefix + "UTZRECLEFT" + IntegerToString(topPTZstartTime));
         ObjectDelete(objprefix + "UTZRECRIGHT" + IntegerToString(topPTZstartTime));
         }
         
      topPTZCheck = false;
      highSpreadDist[highSpread]++;
      rHighSpreadDist[highSpread]++;
      highSpread = 0;
      i = topPTZstartTime;
      topPTZstartTime = 0;
      }
   
   if((topPTZstartTime - i >= hright || i == 0) && topPTZCheck == true) // Top PTZ Failed to Resolve
      {
      if(topPTZstartTime - i >= hright)
         {
         ObjectSet(objprefix + "UTZRECLEFT" + IntegerToString(topPTZstartTime),OBJPROP_COLOR,clrOrange);
         ObjectSet(objprefix + "UTZRECRIGHT" + IntegerToString(topPTZstartTime),OBJPROP_COLOR,clrOrange);
         }
      
      // Delete Rectangles
      if(hideTrueTZs)
         {
         ObjectDelete(objprefix + "UTZRECLEFT" + IntegerToString(topPTZstartTime));
         ObjectDelete(objprefix + "UTZRECRIGHT" + IntegerToString(topPTZstartTime));
         }
         
      totalTopTZs++;
      topPTZCheck = false;
      highSpreadDist[highSpread]++;
      urHighSpreadDist[highSpread]++;
      highSpread = 0;
      i = topPTZstartTime;
      topPTZstartTime = 0;
      }
   
   //----------------------------------
   // Bottom PTZ Data Gathering Section - Long Trades
   //----------------------------------
   // Check if high is above highest or low is below lowest
   if(Low[i] < lowestHLeft && Low[i] < (lowestHLeft - (k*CalculateNormalizedDigits())) && bottomPTZCheck == false && topPTZCheck == false) // Top PTZ Formed
      {
      // Set Top TZ Y Values
      topDownZone = lowestHLeft;
      bottomDownZone = lowestHLeft - (k*CalculateNormalizedDigits());
      
      // Count it
      totalBottomPTZs++;
      
      // Get & log distance
      distance = int(MathRound((topDownZone-Low[i])/CalculateNormalizedDigits()));
      if(distance > lowSpread) {lowSpread = distance;}
      if(distance > lowSpreadMax) {lowSpreadMax = distance;}
      
      // Draw PTZ Rectangle
      rectName = objprefix + "DTZRECLEFT" + IntegerToString(i);
      ObjectCreate(rectName,OBJ_RECTANGLE,0,Time[i+hleft],topDownZone,Time[i],bottomDownZone);
      
      rectName = objprefix + "DTZRECRIGHT" + IntegerToString(i);
      if(i<hright) // Check if rectangle needs to extend past current time
         {
         ObjectCreate(rectName,OBJ_RECTANGLE,0,Time[i],topDownZone,Time[i]+(60*Period() * hright),bottomDownZone);
         }
      else
         {
         ObjectCreate(rectName,OBJ_RECTANGLE,0,Time[i],topDownZone,Time[i-hright],bottomDownZone);
         }
      
      // Set Counters to then look for resolve
      bottomPTZCheck = true;
      bottomPTZstartTime = i;
      }
   
   // Update spread distane
   if(bottomPTZCheck)
      {
      // Get & log distance
      distance = int(MathRound((topDownZone-Low[i])/CalculateNormalizedDigits()));
      if(distance > lowSpread) {lowSpread = distance;}
      if(distance > lowSpreadMax) {lowSpreadMax = distance;}
      }
   
   if((bottomPTZCheck == true && Close[i] > topDownZone && i == bottomPTZstartTime)) // Bottom PTZ Resolved on bar formed
      {
      bottomResolveonFormBar++;
      if(lowSpread < r) {PTZRFRc++;}
      dotName = objprefix+"PTZResolveOnFormBarD"+IntegerToString(i);
      ObjectCreate(dotName, OBJ_TEXT, 0, Time[i], High[i]); 
      ObjectSetText(dotName, "R", 14, "Arial", Red);
      
      // Color Resolved TZ
      ObjectSet(objprefix + "DTZRECLEFT" + IntegerToString(bottomPTZstartTime),OBJPROP_COLOR,clrRed);
      ObjectSet(objprefix + "DTZRECRIGHT" + IntegerToString(bottomPTZstartTime),OBJPROP_COLOR,clrYellow);
      
      // Delete Rectangles
      if(hidePastPTZs)
         {
         ObjectDelete(objprefix + "DTZRECLEFT" + IntegerToString(bottomPTZstartTime));
         ObjectDelete(objprefix + "DTZRECRIGHT" + IntegerToString(bottomPTZstartTime));
         }
         
      bottomPTZCheck = false;
      lowSpreadDist[lowSpread]++;
      rLowSpreadDist[lowSpread]++;
      lowSpread = 0;
      i = bottomPTZstartTime;
      bottomPTZstartTime = 0;
      }
   
   if((bottomPTZCheck == true && High[i] > topDownZone && i != bottomPTZstartTime)) // Top PTZ Resolved after bar formed
      {
      dotName = objprefix+"PTZResolveAfterFormBarD"+IntegerToString(i);
      ObjectCreate(dotName, OBJ_TEXT, 0, Time[i], High[i]); 
      ObjectSetText(dotName, "R", 14, "Arial", Green);
      
      // Color Resolved TZ
      ObjectSet(objprefix + "DTZRECLEFT" + IntegerToString(bottomPTZstartTime),OBJPROP_COLOR,clrRed);
      ObjectSet(objprefix + "DTZRECRIGHT" + IntegerToString(bottomPTZstartTime),OBJPROP_COLOR,clrYellow);
      
      // Delete Rectangles
      if(hidePastPTZs)
         {
         ObjectDelete(objprefix + "DTZRECLEFT" + IntegerToString(bottomPTZstartTime));
         ObjectDelete(objprefix + "DTZRECRIGHT" + IntegerToString(bottomPTZstartTime));
         }
         
      bottomPTZCheck = false;
      lowSpreadDist[lowSpread]++;
      rLowSpreadDist[lowSpread]++;
      lowSpread = 0;
      i = bottomPTZstartTime;
      bottomPTZstartTime = 0;
      }
   
   if((bottomPTZstartTime - i >= hright || i == 0) && bottomPTZCheck == true) // Top PTZ Failed to Resolve
      {
      if(bottomPTZstartTime - i >= hright)
         {
         ObjectSet(objprefix + "DTZRECLEFT" + IntegerToString(bottomPTZstartTime),OBJPROP_COLOR,clrOrange);
         ObjectSet(objprefix + "DTZRECRIGHT" + IntegerToString(bottomPTZstartTime),OBJPROP_COLOR,clrOrange);
         }
      
      // Delete Rectangles
      if(hideTrueTZs)
         {
         ObjectDelete(objprefix + "DTZRECLEFT" + IntegerToString(bottomPTZstartTime));
         ObjectDelete(objprefix + "DTZRECRIGHT" + IntegerToString(bottomPTZstartTime));
         }
         
      totalBottomTZs++;
      bottomPTZCheck = false;
      lowSpreadDist[lowSpread]++;
      urLowSpreadDist[lowSpread]++;
      lowSpread = 0;
      i = bottomPTZstartTime;
      bottomPTZstartTime = 0;
      }
   
   i--;
   }
  
  //--------------------------
  // Add Basic Data to Buffers
  //--------------------------
  TBARS[0] = double(totalTopTZs + totalBottomTZs)/double(lookBack);
  PTZR[0] = 1-(double(totalTopTZs + totalBottomTZs)/double(totalTopPTZs + totalBottomPTZs));
  PTZRF[0] = double(topResolveonFormBar + bottomResolveonFormBar)/double(totalTopPTZs + totalBottomPTZs);
  PTZRFR[0] = double(PTZRFRc)/double(totalTopPTZs + totalBottomPTZs);
  
  //-----------------------------------------------
  // Find All Outcome Probabilties & Add to Buffers
  //-----------------------------------------------
  // Find SL (Resolved within 2k) & RTP (Resolved After Breach r) - Resolves 
  int x = 0;
  int rsum = 0;
  int ursum = 0;
  double runningTotal = 0;
  while(x<highSpreadMax || x<lowSpreadMax)
     {
     rsum+= rHighSpreadDist[x];
     rsum+= rLowSpreadDist[x];
     ursum+= urHighSpreadDist[x];
     ursum+= urLowSpreadDist[x];
     x++;
     }
  
  x = 0;
  while(x<highSpreadMax || x<lowSpreadMax)
   {
   double probability;
   if(rHighSpreadDist[x] == 0 && rLowSpreadDist[x] == 0) {probability = 0;}
   else {probability = double(rHighSpreadDist[x] + rLowSpreadDist[x])/rsum;}
   runningTotal+= probability;
   
   if(x >= r)
      {
      SL[0] = runningTotal * PTZR[0];
      RTP[0] = (1-runningTotal) * PTZR[0];
      break;
      }
   x++;
   }
  
  // Find URNTP (Unresolved but didnt reach r) & URTP (Unresolved & reached r)
  runningTotal = 0;
  x = 0;
  while(x<highSpreadMax || x<lowSpreadMax)
   {
   if(urHighSpreadDist[x] == 0 && urLowSpreadDist[x] == 0) {probability = 0;}
   else {probability = double(urHighSpreadDist[x] + urLowSpreadDist[x])/ursum;}
   runningTotal+= probability;
   
   if(x >= r)
      {
      URNTP[0] = runningTotal * (1-PTZR[0]);
      URTP[0] = (1-runningTotal) * (1-PTZR[0]);
      break;
      }
   x++; 
   }
  
  //-------------------------------------------
  // Set Expansion & Contraction Buffers Values
  //-------------------------------------------
  if(factorSpreadRisk) {ESL[0] = SL[0] + URNTP[0] + ((MarketInfo(Symbol(),MODE_SPREAD)/10)/r);} else {ESL[0] = SL[0] + URNTP[0];}
  if(factorSpreadRisk) {ETP[0] = RTP[0] + URTP[0] - ((MarketInfo(Symbol(),MODE_SPREAD)/10)/r);} else {ETP[0] = RTP[0] + URTP[0];}
  EEV[0] = ((ETP[0] * double(r-k)) - (ESL[0] * double(k)))/double(k);  
  
  if(factorSpreadRisk) {CSL[0] = RTP[0] + URTP[0] + URNTP[0] + ((MarketInfo(Symbol(),MODE_SPREAD)/10)/r);} else {CSL[0] = RTP[0] + URTP[0] + URNTP[0];}
  if(factorSpreadRisk) {CTP[0] = SL[0] - ((MarketInfo(Symbol(),MODE_SPREAD)/10)/r);} else {CTP[0] = SL[0];}
  CEV[0] = ((CTP[0] * double(k)) - (CSL[0] * double(r-k)))/double(r-k);
  
  if(drawStats) {DrawStats(totalTopPTZs, totalTopTZs, totalBottomPTZs, totalBottomTZs, topResolveonFormBar, bottomResolveonFormBar);}
  
  WriteFile();
  return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+
//+----------------
//| Draw Statistics                                            
//+----------------
void DrawStats(int totalTopPTZs, int totalTopTZs, int totalBottomPTZs, int totalBottomTZs, int topResolveonFormBar, int bottomResolveonFormBar)
  {
  int i = 20;
  int j = 2000;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"Inputs",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;  
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"h Left: " + IntegerToString(hleft),7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"h Right: " + IntegerToString(hright),7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"k: " + IntegerToString(k),7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"r: " + IntegerToString(r),7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"r based spread risk: " + DoubleToStr((MarketInfo(Symbol(),MODE_SPREAD)/10)/r*100,2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=20;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"Transient/Recurrent Data",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;  
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"% of True Transiet Bars: " + DoubleToStr(TBARS[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"% of PTZs: " + DoubleToStr((double(totalTopPTZs + totalBottomPTZs)/double(lookBack))*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"% of PTZs that Become TZs: " + DoubleToStr((1-PTZR[0])*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"% of PTZs That Resolve: " + DoubleToStr(PTZR[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"% of PTZs That Resolve on Form Bar: " + DoubleToStr(PTZRF[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=20;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"Buffer Data",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;    
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"SL: " + DoubleToStr(SL[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++; 
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"RTP: " + DoubleToStr(RTP[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++; 
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"URNTP: " + DoubleToStr(URNTP[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"URTP: " + DoubleToStr(URTP[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=20;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"Expansion Setup",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"SL: " + DoubleToStr(ESL[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++; 
    
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"TP: " + DoubleToStr(ETP[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"EV: " + DoubleToStr(EEV[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=20;
  j++; 
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"Contraction Setup",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"SL: " + DoubleToStr(CSL[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++; 
    
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"TP: " + DoubleToStr(CTP[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=10;
  j++;
  
  ObjectCreate(objprefix+IntegerToString(j),OBJ_LABEL,0,0,0);
  ObjectSetText(objprefix+IntegerToString(j),"EV: " + DoubleToStr(CEV[0]*100, 2) + "%",7,"Verdana",Red);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_CORNER,1);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_XDISTANCE,10);
  ObjectSet(objprefix+IntegerToString(j),OBJPROP_YDISTANCE,i);
  i+=20;
  j++;   
  }
//+--------------
//|DELETE OBJECTS                                                 
//+--------------  
void DeleteObjects(string prefix)
  {
  string strObj;
  int ObjTotal=ObjectsTotal();
  for(int i=ObjTotal-1;i>=0;i--)
    {
     strObj=ObjectName(i);
     if(StringFind(strObj,prefix,0)>-1)
       {
        ObjectDelete(strObj);
       }
    }
  }
//+--------------------------
//|WRITE STATISTICS INTO FILE                                        
//+--------------------------
bool WriteFile()
  {
  int file_handle=FileOpen(InpDirectoryName+"//"+InpFileName,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI);
  if(file_handle!=INVALID_HANDLE)
    {
    PrintFormat("%s file is available for writing",InpFileName);
    PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));

    Print("Start of frequency distribution: "+TimeToString(iPeriod_Start,TIME_DATE|TIME_MINUTES));

    string strData="";
   
    strData = strData + "Up TZ Spreads(Short Trades - R & UR)" + "\n";
   
     int x = 0;
     do
        {
        strData = strData + IntegerToString(highSpreadDist[x]) + "\n";
        x++;
        }
     while(x<highSpreadMax);
     
     strData = strData + "Down TZ Spreads(Long Trades  - R & UR)" + "\n";
   
     x = 0;
     do
        {
        strData = strData + IntegerToString(lowSpreadDist[x]) + "\n";
        x++;
        }
     while(x<lowSpreadMax);
     
     strData = strData + "Up TZ Spreads(Short Trades - R)" + "\n";
   
     x = 0;
     do
        {
        strData = strData + IntegerToString(rHighSpreadDist[x]) + "\n";
        x++;
        }
     while(x<highSpreadMax);
     
     strData = strData + "Down TZ Spreads(Long Trades  - R)" + "\n";
   
     x = 0;
     do
        {
        strData = strData + IntegerToString(rLowSpreadDist[x]) + "\n";
        x++;
        }
     while(x<lowSpreadMax);
     
     strData = strData + "Up TZ Spreads(Short Trades - UR)" + "\n";
   
     x = 0;
     do
        {
        strData = strData + IntegerToString(urHighSpreadDist[x]) + "\n";
        x++;
        }
     while(x<highSpreadMax);
     
     strData = strData + "Down TZ Spreads(Long Trades  - UR)" + "\n";
   
     x = 0;
     do
        {
        strData = strData + IntegerToString(urLowSpreadDist[x]) + "\n";
        x++;
        }
     while(x<lowSpreadMax);
       
    FileWriteString(file_handle,strData);

    //--- close the file
    FileClose(file_handle);
    PrintFormat("Data is written, %s file is closed",InpFileName);
      
    return(true);
    }
  else
    {
    PrintFormat("Failed to open %s file, Error code = %d",InpFileName,GetLastError());
    return(false);
    }
  }
//+----------------
//|Normalize Digits                                                  
//+---------------- 
double CalculateNormalizedDigits()
  {
//If there are 3 or less digits (JPY for example) then return 0.01 which is the pip value
   if(Digits<=3)
     {
      return(0.01);
     }
//If there are 4 or more digits then return 0.0001 which is the pip value
   else if(Digits>=4)
     {
      return(0.0001);
     }
//In all other cases (there shouldn't be any) return 0
   else return(0);
  }
