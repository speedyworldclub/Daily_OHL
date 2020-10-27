//+------------------------------------------------------------------+
//|                                          Daily High-Low-Open.mq5 |
//|                                             Copyright Dilwyn Tng |
//|                                           dilwyn2000@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Dilwyn Tng"
#property link      "dilwyn2000@hotmail.com"
#property version   "1.00"
#property description   "Daily High Low and Open Indicator"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

//
//
//
//
//

#property indicator_label1  "High"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrTomato
#property indicator_style1  STYLE_DASH
#property indicator_width1  1

#property indicator_label2  "Low"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLightGreen
#property indicator_style2  STYLE_DASH
#property indicator_width2  1

#property indicator_label3  "Open"
#property indicator_type3   DRAW_SECTION
#property indicator_color3  clrKhaki
#property indicator_style3  STYLE_DASH
#property indicator_width3  1


//
//
//
//
//

input ENUM_TIMEFRAMES inpPeriod      = PERIOD_D1; // Time frame for highs/lows
input int             inpPeriodsBack = 0;         // Look back periods (enter 0 or less than zero for all)

//
//
//
//
//

double HiBuffer[];
double LoBuffer[];
double OpenBuffer[];

int             iPeriodsBack;
ENUM_TIMEFRAMES iPeriod;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnInit()
{




   SetIndexBuffer(0,HiBuffer,INDICATOR_DATA); ArraySetAsSeries(HiBuffer,true);
   SetIndexBuffer(1,LoBuffer,INDICATOR_DATA); ArraySetAsSeries(LoBuffer,true);
   SetIndexBuffer(2,OpenBuffer,INDICATOR_DATA); ArraySetAsSeries(OpenBuffer,true);

   //
   //
   //
   //
   //
   
   iPeriodsBack = (inpPeriodsBack>0) ? inpPeriodsBack : 999999;      
   iPeriod      = (inpPeriod>=Period()) ? inpPeriod : Period();
      string timeFrameName = periodToString(iPeriod);
         IndicatorSetString(INDICATOR_SHORTNAME,timeFrameName+" highs/lows/open");
         PlotIndexSetString(0,PLOT_LABEL,timeFrameName+" high");
         PlotIndexSetString(1,PLOT_LABEL,timeFrameName+" low");
         PlotIndexSetString(2,PLOT_LABEL,timeFrameName+" open");
   return(0);
}

//
//
//
//
//

#define numRetries 5

//
//
//
//
//

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{

   //
   //
   //
   //
   //

   if (!ArrayGetAsSeries(time)) ArraySetAsSeries(time,true);
         MqlRates ratesArray[]; ArraySetAsSeries(ratesArray,true);
         
         int copiedRates;
         for (int i=0; i<numRetries;i++)
            if((copiedRates = CopyRates(Symbol(),iPeriod,time[rates_total-1],time[0],ratesArray))>0) break;
            if (copiedRates <= 0)
            {
               Print("not all rates copied. Will try on next tick");
               return(prev_calculated);
            }

      //
      //
      //
      //
      //

         int limit = rates_total-prev_calculated;
            if (prev_calculated > 0) limit++;
            if (prev_calculated ==0) limit--;

            int minutesPeriod = periodToMinutes(Period());
            int minutesChosen = periodToMinutes(iPeriod);

         limit = (limit>(minutesChosen/minutesPeriod)) ? limit : (minutesChosen/minutesPeriod);

      //
      //
      //
      //
      //
            
      for (int i=limit; i>=0; i--)
      {
         int d = dateArrayBsearch(ratesArray,time[i],copiedRates);
         
         if (d >= 0 && d < iPeriodsBack)
            {
               HiBuffer[i] = ratesArray[d].high;
               LoBuffer[i] = ratesArray[d].low;
              // OpenBuffer[i] = iOpen(_Symbol,PERIOD_D1,0);
               OpenBuffer[i] = ratesArray[d].open;
            }
         else
            {
               HiBuffer[i] = EMPTY_VALUE;
               LoBuffer[i] = EMPTY_VALUE;
               OpenBuffer[i] = EMPTY_VALUE;
            }
      }
   
   //
   //
   //
   //
   //

   return(rates_total);
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int dateArrayBsearch(MqlRates& rates[], datetime toFind, int total)
{
   int mid   = 0;
   int first = 0;
   int last  = total-1;
   
   while (last >= first)
   {
      mid = (first + last) >> 1;
      if (toFind == rates[mid].time || (mid > 0 && (toFind > rates[mid].time) && (toFind < rates[mid-1].time))) break;
      if (toFind >  rates[mid].time)
            last  = mid - 1;
      else  first = mid + 1;
   }
   return (mid);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int periodToMinutes(int period)
{
   int i;
   static int _per[]={1,2,3,4,5,6,10,12,15,20,30,0x4001,0x4002,0x4003,0x4004,0x4006,0x4008,0x400c,0x4018,0x8001,0xc001};
   static int _min[]={1,2,3,4,5,6,10,12,15,20,30,60,120,180,240,360,480,720,1440,10080,43200};

   if (period==PERIOD_CURRENT) 
       period = Period();   
            for(i=0;i<20;i++) if(period==_per[i]) break;
   return(_min[i]);   
}

//
//
//
//
//

string periodToString(int period)
{
   int i;
   static int    _per[]={1,2,3,4,5,6,10,12,15,20,30,0x4001,0x4002,0x4003,0x4004,0x4006,0x4008,0x400c,0x4018,0x8001,0xc001};
   static string _tfs[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes",
                         "15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours",
                         "12 hours","daily","weekly","monthly"};
   
   if (period==PERIOD_CURRENT) 
       period = Period();   
            for(i=0;i<20;i++) if(period==_per[i]) break;
   return(_tfs[i]);   
}

