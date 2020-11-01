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
#property indicator_style1  STYLE_DOT
#property indicator_width1  1

#property indicator_label2  "Low"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLightGreen
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

#property indicator_label3  "Open"
#property indicator_type3   DRAW_SECTION
#property indicator_color3  clrKhaki
#property indicator_style3 STYLE_DOT
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

//=================================================News=====================================

#define EMPTY                     -1
#define   GMT_OFFSET_WINTER_DEFAULT 2
#define   GMT_OFFSET_SUMMER_DEFAULT 3


enum news_type
{
   NewsBasedOnCurrentSymbol,//Based on Symbol Currencies
   NewsBasedOnListOfSymbol,//Based on List of Symbol
   NewsBasedOnKeywords,//Based on List of keywords on Title 
   NewsBasedOnCurrentSymbolAndKeywords,//Based on Symbol Currencies & List of keywords on Title
   NewsBasedOnListOfSymbolAndKeywords,//Based on List of Symbol & List of keywords on Title
   NewsBasedOnAllNews//Based on All News on All Symbols
};


input string    ns          ="====================================";               //====== News Settings ======
input bool      Use_News_Filter                                      = true;                       //Show News
//input bool      Use_News_Filter_For_Back_Test                        = true;  //Avoid News Back Test
input news_type News_Type = NewsBasedOnListOfSymbol;//News Type
input int       Max_Line_Of_News=10;//Max Line Of News
input int       FutureNewsLine=80;//Percentage of future news 
input string    nsh          ="";               //====== High ======
input bool      High_Impact                                          = true;                        //High Impact News
input string    High_News_Symbols = "AUD|CAD|CHF|EUR|GBP|JPY|NZD|USD";//Symbols Separated by |
input string    High_News_Keywords = "";//Keywords Seperated by |
input int       News_display_minutes_before_current_time_High = 720; //News Display Minutes Before Current Time - High 
input int       News_display_minutes_after_current_time_High = 180;  //News Display Minutes After Current Time - High
input int       Minutes_Before_High_News                                  = 120;                           //Stop Minutes Before News - High
input int       Minutes_After_High_News                                   = 45;                          //Start Minutes After News - High
input color     High_Impact_Color = Red;//High Impact News Color

input string    nsm          ="";               //====== Medium ======
input bool      Medium_Impact                                        = true;                        //Medium Impact News
input string    Medium_News_Symbols = "AUD|CAD|CHF|EUR|GBP|JPY|NZD|USD";//Symbols Separated by |
input string    Medium_News_Keywords = "";//Keywords Seperated by |
input int       News_display_minutes_before_current_time_Medium = 300; //News Display Minutes Before Current Time - Medium 
input int       News_display_minutes_after_current_time_Medium = 90;  //News Display Minutes After Current Time - Medium
input int       Minutes_Before_Medium_News                                  = 60;                           //Stop Minutes Before News - Medium
input int       Minutes_After_Medium_News                                   = 30;                          //Start Minutes After News - Medium
input color     Medium_Impact_Color = Orange;//Mid Impact News Color

input string    nsl          ="";               //====== Low ======             
input bool      Low_Impact                                          = false;                        //Low Impact News
input string    Low_News_Symbols = "AUD|CAD|CHF|EUR|GBP|JPY|NZD|USD";//Symbols Separated by |
input string    Low_News_Keywords = "";//Keywords Seperated by |
input int       News_display_minutes_before_current_time_Low = 0; //News Display Minutes Before Current Time - Low 
input int       News_display_minutes_after_current_time_Low = 0;  //News Display Minutes After Current Time - Low
input int       Minutes_Before_Low_News                                  = 0;                           //Stop Minutes Before News - Low
input int       Minutes_After_Low_News                                   = 0;                          //Start Minutes After News - Low
input color     Low_Impact_Color = Yellow;//Low Impact News Color

//input bool      BuySellEachBar=false; //Inject Random Position

datetime BarTime      = 0;
int    MinUntilHighNews                                              = 0, MinUntilMediumNews = 0, MinUntilLowNews = 0;
int    MinSinceHighNews                                              = 0, MinSinceMediumNews = 0, MinSinceLowNews = 0;

datetime PreviousEntryTime = 0;
string NewsImportance, NewsStartTime, NewsEndTime;
datetime Next_News_Time_High = 0, Next_News_Time_Medium = 0, Next_News_Time_Low = 0;
datetime Previous_News_Time_High = 0, Previous_News_Time_Medium = 0, Previous_News_Time_Low = 0;
string HighNewsKeywords[], MediumNewsKeywords[], LowNewsKeywords[];
string HighNewsSymbols[], MediumNewsSymbols[], LowNewsSymbols[];
string NewsArray[, 4];
string NewsPrefix = "NewsInfo_";
datetime EA_Start_Time = 0;
string HistoryFileName = "news\\"+AccountInfoString(ACCOUNT_SERVER)+"_newshistory.bin";


color currentColor=High_Impact_Color;

enum ENUM_COUNTRY_ID
  {
   World=0,
   EU=999,
   USA=840,
   Canada=124,
   Australia=36,
   NewZealand=554,
   Japan=392,
   China=156,
   UK=826,
   Switzerland=756,
   Germany=276,
   France=250,
   Italy=380,
   Spain=724,
   Brazil=76,
   SouthKorea=410
  };

class CNews
  {
private:
   struct            EventStruct
                       {
                        ulong    value_id;
                        ulong    event_id;
                        datetime time;
                        datetime period;
                        int      revision;
                        long     actual_value;
                        long     prev_value;
                        long     revised_prev_value;
                        long     forecast_value;
                        ENUM_CALENDAR_EVENT_IMPACT impact_type;
                        ENUM_CALENDAR_EVENT_TYPE event_type;
                        ENUM_CALENDAR_EVENT_SECTOR sector;
                        ENUM_CALENDAR_EVENT_FREQUENCY frequency;
                        ENUM_CALENDAR_EVENT_TIMEMODE timemode;
                        ENUM_CALENDAR_EVENT_IMPORTANCE importance;
                        ENUM_CALENDAR_EVENT_MULTIPLIER multiplier;
                        ENUM_CALENDAR_EVENT_UNIT unit;
                        uint     digits;
                        ulong    country_id; // ISO 3166-1
                       };
   string            future_eventname[];
   MqlDateTime       tm;
   datetime          servertime;
   datetime          GMT(ushort server_offset_winter,ushort server_offset_summer);   
public:
   EventStruct       event[];
   string            eventname[];
   int               SaveHistory(bool printlog_info=false);
   int               LoadHistory(bool printlog_info=false);
   int               update(int interval_seconds,bool printlog_info=false);
   int               next(int pointer_start,string currency,bool show_on_chart,long chart_id);
   string            CountryIdToCurrency(ENUM_COUNTRY_ID c);
   int               CurrencyToCountryId(string currency);    
   datetime          last_update;
   ushort            GMT_offset_winter;
   ushort            GMT_offset_summer;    
                     CNews(void)
                       {
                        ArrayResize(event,150000,0);ZeroMemory(event);//100000
                        ArrayResize(eventname,150000,0);ZeroMemory(eventname);//100000
                        ArrayResize(future_eventname,150000,0);ZeroMemory(future_eventname);//100000
                        GMT_offset_winter=GMT_OFFSET_WINTER_DEFAULT;
                        GMT_offset_summer=GMT_OFFSET_SUMMER_DEFAULT;
                        last_update=0;
                        SaveHistory(true);
                        LoadHistory(true);
                       }
                    ~CNews(void){};
  };

CNews news;  
  
//==================================================News




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

//================= news
 news=CNews();
    EventSetMillisecondTimer(200); 

    EA_Start_Time = TimeCurrent();

    uchar seperator = '|';
    
    StringSplit(High_News_Keywords, seperator, HighNewsKeywords);
    StringSplit(Medium_News_Keywords, seperator, MediumNewsKeywords);
    StringSplit(Low_News_Keywords, seperator, LowNewsKeywords);

    StringSplit(High_News_Symbols, seperator, HighNewsSymbols);
    StringSplit(Medium_News_Symbols, seperator, MediumNewsSymbols);
    StringSplit(Low_News_Symbols, seperator, LowNewsSymbols);
    
    Comment("");    // clear the chart
//================ news



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
   //return(0);
     return (INIT_SUCCEEDED);
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


//=============== news
datetime lastTradeTime=0;
bool CheckTimeTrade=true;
void OnTick()
{
    if (!MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_OPTIMIZATION) ) int total_events=news.update();
    
    
    if (Use_News_Filter) //check news
    CheckNews();    
        
    int News_Y = 0;        
    
    if (Use_News_Filter)
    ShowNewsInfo(News_Y);
    


    
}

void OnDeinit(const int reason)
{
  /*  string Name;
    for (int i = ObjectsTotal() - 1; i >= 0; i--)
    {
        Name = ObjectName(i);
        if (StringSubstr(Name, 0, 7) == "NoTrade")
            ObjectDelete(Name);
    } 
  */   
    
    RemoveObjects(NewsPrefix);
    
   // RemoveObjects(RestartConsecutiveLoss_Button);
}

    
//======== news

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


//============ news by T



//+------------------------------------------------------------------+
//| update news events (file and buffer arrays)                      |
//+------------------------------------------------------------------+
int CNews::update(int interval_seconds=60,bool printlog_info=false)
  {
   static datetime last_time=0;
   static int total_events=0;
   if (TimeCurrent()<last_time+interval_seconds){return total_events;}
   SaveHistory(printlog_info);
   total_events=LoadHistory(printlog_info);
   last_time=TimeCurrent();
   return total_events;
  }

//+------------------------------------------------------------------+
//| grab news history and save it to disk                            |
//+------------------------------------------------------------------+
int CNews::SaveHistory(bool printlog_info=false)
  {
   datetime tm_gmt=TimeCurrent();//GMT(GMT_offset_winter,GMT_offset_summer);
   int filehandle;
   
   // create or open history file
   if (!FileIsExist(HistoryFileName,FILE_COMMON))
     {
      filehandle=FileOpen(HistoryFileName,FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      if (filehandle!=INVALID_HANDLE){if(printlog_info){Print(__FUNCTION__,": creating new file common/files/news/newshistory.bin");}}
      else {if (printlog_info){Print(__FUNCTION__,"invalid filehandle, can't create news history file");}return 0;}
      FileSeek(filehandle,0,SEEK_SET);
      FileWriteLong(filehandle,(long)last_update);
     }
   else
     {
      filehandle=FileOpen(HistoryFileName,FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      FileSeek(filehandle,0,SEEK_SET);
      last_update=(datetime)FileReadLong(filehandle);
      if (filehandle!=INVALID_HANDLE){if(printlog_info){Print(__FUNCTION__,": previous newshistory file found in common/files; history update starts from ",last_update," GMT");}}
      else {if(printlog_info){Print(__FUNCTION__,": invalid filehandle; can't open previous news history file");};return 0;}
      bool from_beginning=FileSeek(filehandle,0,SEEK_END);
      if(!from_beginning){Print(__FUNCTION__": unable to go to the file's beginning");}
     }
   if (last_update>tm_gmt)
     {
      if (printlog_info)
        {Print(__FUNCTION__,": time of last news update is in the future relative to timestamp of request; the existing data won't be overwritten/replaced,",
         "\nexecution of function therefore prohibited; only future events relative to this timestamp will be loaded");}
      return 0; //= number of new events since last update
     }
     
   // get entire event history from last update until now
   MqlCalendarValue eventvaluebuffer[];ZeroMemory(eventvaluebuffer);
   MqlCalendarEvent eventbuffer;ZeroMemory(eventbuffer);
   CalendarValueHistory(eventvaluebuffer,last_update,tm_gmt);
   
   int number_of_events=ArraySize(eventvaluebuffer);
   int saved_elements=0;
   if (number_of_events>=ArraySize(event)){ArrayResize(event,number_of_events,0);}
   for (int i=0;i<number_of_events;i++)
     {
      event[i].value_id          =  eventvaluebuffer[i].id;
      event[i].event_id          =  eventvaluebuffer[i].event_id;
      event[i].time              =  eventvaluebuffer[i].time;
      event[i].period            =  eventvaluebuffer[i].period;
      event[i].revision          =  eventvaluebuffer[i].revision;
      event[i].actual_value      =  eventvaluebuffer[i].actual_value;
      event[i].prev_value        =  eventvaluebuffer[i].prev_value;
      event[i].revised_prev_value=  eventvaluebuffer[i].revised_prev_value;
      event[i].forecast_value    =  eventvaluebuffer[i].forecast_value;
      event[i].impact_type       =  eventvaluebuffer[i].impact_type;
      
      CalendarEventById(eventvaluebuffer[i].event_id,eventbuffer);
      
      event[i].event_type        =  eventbuffer.type;
      event[i].sector            =  eventbuffer.sector;
      event[i].frequency         =  eventbuffer.frequency;
      event[i].timemode          =  eventbuffer.time_mode;
      event[i].importance        =  eventbuffer.importance;
      event[i].multiplier        =  eventbuffer.multiplier;
      event[i].unit              =  eventbuffer.unit;
      event[i].digits            =  eventbuffer.digits;
      event[i].country_id        =  eventbuffer.country_id;
      if (event[i].event_type!=CALENDAR_TYPE_HOLIDAY &&           // ignore holiday events
         event[i].timemode==CALENDAR_TIMEMODE_DATETIME)           // only events with exactly published time
        {
         FileWriteStruct(filehandle,event[i]);
         int length=StringLen(eventbuffer.name);
         FileWriteInteger(filehandle,length,INT_VALUE);
         FileWriteString(filehandle,eventbuffer.name,length);
         saved_elements++; 
        }
     }
   // renew update time
   FileSeek(filehandle,0,SEEK_SET);
   FileWriteLong(filehandle,(long)tm_gmt);
   FileClose(filehandle);
   if (printlog_info)
      {Print(__FUNCTION__,": ",number_of_events," total events found, ",saved_elements,
      " events saved (holiday events and events without exact published time are ignored)");}
   return saved_elements; //= number of new events since last update
  }

//+------------------------------------------------------------------+
//| load history                                                     |
//+------------------------------------------------------------------+
int CNews::LoadHistory(bool printlog_info=false)
  {
   datetime dt_gmt=TimeCurrent();//GMT(GMT_offset_winter,GMT_offset_summer);
   int filehandle;
   int number_of_events=0;
   
   // open history file
   if (FileIsExist(HistoryFileName,FILE_COMMON))
     {
      filehandle=FileOpen(HistoryFileName,FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      FileSeek(filehandle,0,SEEK_SET);
      last_update=(datetime)FileReadLong(filehandle);
      if (filehandle!=INVALID_HANDLE){if (printlog_info){Print (__FUNCTION__,": previous news history file found; last update was on ",last_update," (GMT)");}}
      else {if (printlog_info){Print(__FUNCTION__,": can't open previous news history file; invalid file handle");}return 0;}
      
      ZeroMemory(event);
      // read all stored events
      int i=0;
      while (!FileIsEnding(filehandle) && !IsStopped())
         {
         if (ArraySize(event)<i+1){
           ArrayResize(event,i+1000);
           ArrayResize(eventname,i+1000);
         }
         FileReadStruct(filehandle,event[i]);
         int length=FileReadInteger(filehandle,INT_VALUE);
         eventname[i]=FileReadString(filehandle,length);
         datetime myTime=TimeCurrent()-5*3600;
         //if(event[i].time > myTime){
         //if(i> 116600){
         //   printf(event[i].time+": "+eventname[i]);
         //}
         //printf(i);
         i++;
        }
        
      number_of_events=i;
      // FileClose(filehandle);
      if (printlog_info)
        {Print(__FUNCTION__,": loading of event history completed (",number_of_events," events), continuing with events after ",last_update," (GMT) ...");}
     }
   else
     {
      if (printlog_info)
        {Print(__FUNCTION__,": no newshistory file found, only upcoming events will be loaded");}
      last_update=dt_gmt;
     }
     
   // get future events
   MqlCalendarValue eventvaluebuffer[];ZeroMemory(eventvaluebuffer);
   MqlCalendarEvent eventbuffer;ZeroMemory(eventbuffer);
   CalendarValueHistory(eventvaluebuffer,last_update,0);
   int future_events=ArraySize(eventvaluebuffer);
   if (printlog_info)
     {Print(__FUNCTION__,": ",future_events," new events found (holiday events and events without published exact time will be ignored)");}
   EventStruct future[];ArrayResize(future,future_events,0);ZeroMemory(future);
   ArrayResize(event,number_of_events+future_events);
   ArrayResize(eventname,number_of_events+future_events);
   for (int i=0;i<future_events;i++)
     {

      future[i].value_id          =  eventvaluebuffer[i].id;
      future[i].event_id          =  eventvaluebuffer[i].event_id;
      future[i].time              =  eventvaluebuffer[i].time;
      future[i].period            =  eventvaluebuffer[i].period;
      future[i].revision          =  eventvaluebuffer[i].revision;
      future[i].actual_value      =  eventvaluebuffer[i].actual_value;
      future[i].prev_value        =  eventvaluebuffer[i].prev_value;
      future[i].revised_prev_value=  eventvaluebuffer[i].revised_prev_value;
      future[i].forecast_value    =  eventvaluebuffer[i].forecast_value;
      future[i].impact_type       =  eventvaluebuffer[i].impact_type;
      
      CalendarEventById(eventvaluebuffer[i].event_id,eventbuffer);
      
      future[i].event_type        =  eventbuffer.type;
      future[i].sector            =  eventbuffer.sector;
      future[i].frequency         =  eventbuffer.frequency;
      future[i].timemode          =  eventbuffer.time_mode;
      future[i].importance        =  eventbuffer.importance;
      future[i].multiplier        =  eventbuffer.multiplier;
      future[i].unit              =  eventbuffer.unit;
      future[i].digits            =  eventbuffer.digits;
      future[i].country_id        =  eventbuffer.country_id;
      future_eventname[i]         =  eventbuffer.name;
      if (future[i].event_type!=CALENDAR_TYPE_HOLIDAY &&           // ignore holiday events
         future[i].timemode==CALENDAR_TIMEMODE_DATETIME)           // only events with exactly published time
        {
         number_of_events++;
         event[number_of_events]=future[i];
         eventname[number_of_events]=future_eventname[i];
        }
     }
   if (printlog_info)
     {Print(__FUNCTION__,": loading of news history completed, ",number_of_events," events in memory");}
   last_update=dt_gmt;
   return number_of_events;
  }

// +------------------------------------------------------------------+
// | get pointer to next event for given currency                     |
// +------------------------------------------------------------------+
int CNews::next(int pointer_start,string currency,bool show_on_chart=true,long chart_id=0)
  {
   datetime dt_gmt=TimeCurrent();//GMT(GMT_offset_winter,GMT_offset_summer);
   for (int p=pointer_start;p<ArraySize(event);p++)
     {
      if 
        (
         event[p].country_id==CurrencyToCountryId(currency) &&
         event[p].time>=dt_gmt
        )
        {
         if (pointer_start!=p && show_on_chart && MQLInfoInteger(MQL_VISUAL_MODE))
           {
            ObjectCreate(chart_id,"event "+IntegerToString(p),OBJ_VLINE,0,event[p].time+TimeTradeServer()-dt_gmt,0);
            ObjectSetInteger(chart_id,"event "+IntegerToString(p),OBJPROP_WIDTH,3);
            ObjectCreate(chart_id,"label "+IntegerToString(p),OBJ_TEXT,0,event[p].time+TimeTradeServer()-dt_gmt,SymbolInfoDouble(Symbol(),SYMBOL_BID));
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_YOFFSET,800);
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_BACK,true);
            ObjectSetString(chart_id,"label "+IntegerToString(p),OBJPROP_FONT,"Arial");
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_FONTSIZE,10);
            ObjectSetDouble(chart_id,"label "+IntegerToString(p),OBJPROP_ANGLE,-90);
            ObjectSetString(chart_id,"label "+IntegerToString(p),OBJPROP_TEXT,eventname[p]);
           }
         return p;         
        }
     }
   return pointer_start;
  }

//+------------------------------------------------------------------+
//| country id to currency                                           |
//+------------------------------------------------------------------+
string CNews::CountryIdToCurrency(ENUM_COUNTRY_ID c)
  {
   switch(c)
     {
      case 999:      return "EUR";     // EU
      case 840:      return "USD";     // USA
      case 36:       return "AUD";     // Australia
      case 554:      return "NZD";     // NewZealand
      case 156:      return "CYN";     // China
      case 826:      return "GBP";     // UK
      case 756:      return "CHF";     // Switzerland
      case 276:      return "EUR";     // Germany
      case 250:      return "EUR";     // France
      case 380:      return "EUR";     // Italy
      case 724:      return "EUR";     // Spain
      case 76:       return "BRL";     // Brazil
      case 410:      return "KRW";     // South Korea
      default:       return "";
     }
  }  
  
//+------------------------------------------------------------------+
//| currency to country id                                           |
//+------------------------------------------------------------------+
int CNews::CurrencyToCountryId(string currency)
  {
   if (currency=="EUR"){return 999;}
   if (currency=="USD"){return 840;}
   if (currency=="AUD"){return 36;}
   if (currency=="NZD"){return 554;}
   if (currency=="CYN"){return 156;}
   if (currency=="GBP"){return 826;}
   if (currency=="CHF"){return 756;}
   if (currency=="BRL"){return 76;}
   if (currency=="KRW"){return 410;}
   return 0;
  }

//+------------------------------------------------------------------+
//| convert server time to GMT                                       |
//| (=for correct GMT time during both testing and live trading)     |
//+------------------------------------------------------------------+
datetime CNews::GMT(ushort server_offset_winter,ushort server_offset_summer)
  {
   // CASE 1: LIVE ACCOUNT
   if (!MQLInfoInteger(MQL_OPTIMIZATION) && !MQLInfoInteger(MQL_TESTER)){return TimeGMT();}
   
   // CASE 2: TESTER or OPTIMIZER
   servertime=TimeCurrent(); //=should be the same as TimeTradeServer() in tester mode, however, the latter sometimes leads to performance issues
   TimeToStruct(servertime,tm);
   static bool initialized=false;
   static bool summertime=true;
   // make a rough guess
   if (!initialized)
     {
      if (tm.mon<=2 || (tm.mon==3 && tm.day<=7)) {summertime=false;}
      if ((tm.mon==11 && tm.day>=8) || tm.mon==12) {summertime=false;}
      initialized=true;
     }
   // switch to summertime
   if (tm.mon==3 && tm.day>7 && tm.day_of_week==0 && tm.hour==7+server_offset_winter) // second sunday in march, 7h UTC New York=2h local winter time
     {
      summertime=true;
     }
   // switch to wintertime
   if (tm.mon==11 && tm.day<=7 && tm.day_of_week==0 && tm.hour==7+server_offset_summer) // first sunday in november, 7h UTC New York=2h local summer time
     {
      summertime=false;
     }
   if (summertime){return servertime-server_offset_summer*3600;}
   else {return servertime-server_offset_winter*3600;}
  }
  
//-======= news by T===============================================================================================================

//=== news by M===================================================================================================================



void CheckNews()
{
    Next_News_Time_High = 0;
    Next_News_Time_Medium = 0;
    Next_News_Time_Low = 0;
    Previous_News_Time_High = 0;
    Previous_News_Time_Medium = 0;
    Previous_News_Time_Low = 0;
    
    datetime date_from = TimeCurrent() - 864000;//take all events from 1 day ago
    datetime date_to = TimeCurrent() + 864000;//take trades until next 1 day
    
    MqlCalendarValue all_events[];
    
    bool newBasedOnCurrentSymbol=false;
    bool newsBasedOnListOfSymbol=false;
    bool newsBasedOnKeywords=false;
    bool newsBasedOnAllNews=false;
    if(News_Type == NewsBasedOnCurrentSymbol) newBasedOnCurrentSymbol=true;
    if(News_Type == NewsBasedOnListOfSymbol) newsBasedOnListOfSymbol=true;
    if(News_Type == NewsBasedOnKeywords) newsBasedOnKeywords= true;
    if(News_Type == NewsBasedOnCurrentSymbolAndKeywords) {
        newBasedOnCurrentSymbol=true;
        newsBasedOnKeywords= true;
    }
    if(News_Type == NewsBasedOnListOfSymbolAndKeywords){
        newsBasedOnListOfSymbol=true;
        newsBasedOnKeywords= true;
    }
    if(News_Type == NewsBasedOnAllNews){
        newsBasedOnAllNews=true;
    }

    //if (News_Type == NewsBasedOnCurrentSymbol)
    if(newBasedOnCurrentSymbol)
    {
       MqlCalendarValue currency1_events[];
       MqlCalendarValue currency2_events[];
       
       string currency1 = StringSubstr(Symbol(), 0, 3);
       string currency2 = StringSubstr(Symbol(), 3, 3);
       
       CalendarValueHistory(currency1_events,date_from,date_to,NULL,currency1);
       CalendarValueHistory(currency2_events,date_from,date_to,NULL,currency2);
       
       if (currency1 == "CNY" || currency1 == "AUD" ||  currency1 == "USD" || currency1 == "GBP" || currency1 == "EUR" || currency1 == "JPY" || currency1 == "CHF" || currency1 == "CAD" || currency1 == "NZD")
         ArrayInsert(all_events, currency1_events, 0, 0, WHOLE_ARRAY);
       
       int start = ArraySize(all_events);
       
       if (currency2 == "CNY" ||currency2 == "AUD" ||  currency2 == "USD" || currency2 == "GBP" || currency2 == "EUR" || currency2 == "JPY" || currency2 == "CHF" || currency2 == "CAD" || currency2 == "NZD")
         ArrayInsert(all_events, currency2_events, start, 0, WHOLE_ARRAY);
    }
    if (newsBasedOnListOfSymbol){
        
        for(int i=0; i<ArraySize(HighNewsSymbols); i++){ 
            MqlCalendarValue currency_events[];
            string currency = HighNewsSymbols[i];
            CalendarValueHistory(currency_events,date_from,date_to,NULL,currency);
            int start = ArraySize(all_events);
            if (currency == "CNY" || currency == "AUD" ||  currency == "USD" || currency == "GBP" || currency == "EUR" || currency == "JPY" || currency == "CHF" || currency == "CAD" || currency == "NZD")
            ArrayInsert(all_events, currency_events, start, 0, WHOLE_ARRAY);
        }
        for(int i=0; i<ArraySize(MediumNewsSymbols); i++){ 
            MqlCalendarValue currency_events[];
            string currency = MediumNewsSymbols[i];
            CalendarValueHistory(currency_events,date_from,date_to,NULL,currency);
            int start = ArraySize(all_events);
            if (currency == "CNY" || currency == "AUD" ||  currency == "USD" || currency == "GBP" || currency == "EUR" || currency == "JPY" || currency == "CHF" || currency == "CAD" || currency == "NZD")
            ArrayInsert(all_events, currency_events, start, 0, WHOLE_ARRAY);
        }
        for(int i=0; i<ArraySize(LowNewsSymbols); i++){ 
            MqlCalendarValue currency_events[];
            string currency = LowNewsSymbols[i];
            CalendarValueHistory(currency_events,date_from,date_to,NULL,currency);
            int start = ArraySize(all_events);
            if (currency == "CNY" || currency == "AUD" ||  currency == "USD" || currency == "GBP" || currency == "EUR" || currency == "JPY" || currency == "CHF" || currency == "CAD" || currency == "NZD")
            ArrayInsert(all_events, currency_events, start, 0, WHOLE_ARRAY);
        }
    }
    if(newsBasedOnKeywords){
        MqlCalendarValue all_events_temp[];
        CalendarValueHistory(all_events_temp, date_from, date_to, NULL, NULL);

        for(int i = 0 ; i < ArraySize(all_events_temp) ; i++)
        {
            int event_id = (int)all_events_temp[i].event_id;
            MqlCalendarEvent event;
            CalendarEventById(event_id, event);
            
            int Event_Importance = event.importance;

            if (Event_Importance == CALENDAR_IMPORTANCE_HIGH)
                if (KeyWordExists(HighNewsKeywords, event.name)){
                    int start = ArraySize(all_events);
                    ArrayInsert(all_events, all_events_temp, start, i, 1);
                }
            
            if (Event_Importance == CALENDAR_IMPORTANCE_MODERATE)
                if (KeyWordExists(MediumNewsKeywords, event.name)){
                    int start = ArraySize(all_events);
                    ArrayInsert(all_events, all_events_temp, start, i, 1);
                }
                
            
            if (Event_Importance == CALENDAR_IMPORTANCE_LOW)
                if (KeyWordExists(LowNewsKeywords, event.name)){
                    int start = ArraySize(all_events);
                    ArrayInsert(all_events, all_events_temp, start, i, 1);
                }
            
        }
      
    }
    if(newsBasedOnAllNews) 
    {
       CalendarValueHistory(all_events, date_from, date_to, NULL, NULL);
    }
    
    
    ArrayResize(NewsArray, 0);
    
    
    for(int i = 0 ; i < ArraySize(all_events) ; i++)
    {

      int event_id = (int)all_events[i].event_id;    
      
      MqlCalendarEvent event;
      CalendarEventById(event_id, event);
      
      
      int Event_Importance = event.importance;
      /*
      
      if (News_Type == NewsBasedOnKeywords)
      {
         if (Event_Importance == CALENDAR_IMPORTANCE_HIGH)
            if (!KeyWordExists(HighNewsKeywords, event.name))
               continue;
         
         if (Event_Importance == CALENDAR_IMPORTANCE_MODERATE)
            if (!KeyWordExists(MediumNewsKeywords, event.name))
               continue;
         
         if (Event_Importance == CALENDAR_IMPORTANCE_LOW)
            if (!KeyWordExists(LowNewsKeywords, event.name))
               continue;
      }
      */
           
      MqlCalendarValue value;
      CalendarValueById(all_events[i].id,value);
          
      AddToNewsArray(event, value);
         
      datetime Event_Time = value.time;

      if (Event_Time >= TimeCurrent())//event has not happened yet
      {
         if (Event_Importance == CALENDAR_IMPORTANCE_HIGH)
            if (Next_News_Time_High == 0 || Event_Time - TimeCurrent() < Next_News_Time_High - TimeCurrent())
               Next_News_Time_High = Event_Time;
               
         
         if (Event_Importance == CALENDAR_IMPORTANCE_MODERATE)
            if (Next_News_Time_Medium == 0 || Event_Time - TimeCurrent() < Next_News_Time_Medium - TimeCurrent())
               Next_News_Time_Medium = Event_Time;
               
         
         if (Event_Importance == CALENDAR_IMPORTANCE_LOW)
            if (Next_News_Time_Low == 0 || Event_Time - TimeCurrent() < Next_News_Time_Low - TimeCurrent())
               Next_News_Time_Low = Event_Time;
      }
      else//event has already happened
      {
         if (Event_Importance == CALENDAR_IMPORTANCE_HIGH)
            if (Previous_News_Time_High == 0 || TimeCurrent() - Event_Time < TimeCurrent() - Previous_News_Time_High)
               Previous_News_Time_High = Event_Time;
                      
         if (Event_Importance == CALENDAR_IMPORTANCE_MODERATE)
            if (Previous_News_Time_Medium == 0 || TimeCurrent() - Event_Time < TimeCurrent() - Previous_News_Time_Medium)
               Previous_News_Time_Medium = Event_Time;
                        
         if (Event_Importance == CALENDAR_IMPORTANCE_LOW)
            if (Previous_News_Time_Low == 0 || TimeCurrent() - Event_Time < TimeCurrent() - Previous_News_Time_Low)
               Previous_News_Time_Low = Event_Time;
      }
    }
    
    
    MinUntilHighNews   = (int)((Next_News_Time_High - TimeCurrent()) / 60);
    MinUntilMediumNews = (int)((Next_News_Time_Medium - TimeCurrent()) / 60);
    MinUntilLowNews    = (int)((Next_News_Time_Low - TimeCurrent()) / 60);

    MinSinceHighNews   = (int)((TimeCurrent() - Previous_News_Time_High) / 60);
    MinSinceMediumNews = (int)((TimeCurrent() - Previous_News_Time_Medium) / 60);
    MinSinceLowNews    = (int)((TimeCurrent() - Previous_News_Time_Low) / 60);
}




bool NewsTime()
{
    bool NewsTime = false;


    if (Low_Impact)
    {
        if (MinUntilLowNews <= Minutes_Before_Low_News)
        {
            NewsTime = true;
            NewsImportance = "Low";
            NewsStartTime = TimeToString(Next_News_Time_Low - Minutes_Before_High_News * 60, TIME_MINUTES);
            NewsEndTime = TimeToString(Next_News_Time_Low + Minutes_After_High_News * 60, TIME_MINUTES);
        }
        else if (MinSinceLowNews <= Minutes_After_Low_News)
        {
            NewsTime = true;
            NewsImportance = "Low";
            NewsStartTime = TimeToString(Previous_News_Time_Low - Minutes_Before_High_News * 60, TIME_MINUTES);
            NewsEndTime = TimeToString(Previous_News_Time_Low + Minutes_After_High_News * 60, TIME_MINUTES);
        }
    }
    
    if (Medium_Impact)
    {
        if (MinUntilMediumNews <= Minutes_Before_Medium_News)
        {
            NewsTime = true;
            NewsImportance = "Medium";
            NewsStartTime = TimeToString(Next_News_Time_Medium - Minutes_Before_High_News * 60, TIME_MINUTES);
            NewsEndTime = TimeToString(Next_News_Time_Medium + Minutes_After_High_News * 60, TIME_MINUTES);
        }
        else if (MinSinceMediumNews <= Minutes_After_Medium_News)
        {
            NewsTime = true;
            NewsImportance = "Medium";
            NewsStartTime = TimeToString(Previous_News_Time_Medium - Minutes_Before_High_News * 60, TIME_MINUTES);
            NewsEndTime = TimeToString(Previous_News_Time_Medium + Minutes_After_High_News * 60, TIME_MINUTES);
        }
    }
    
    if (High_Impact)
    {
        if (MinUntilHighNews <= Minutes_Before_High_News)
        {
            NewsTime = true;
            NewsImportance = "High";
            NewsStartTime = TimeToString(Next_News_Time_High - Minutes_Before_High_News * 60, TIME_MINUTES);
            NewsEndTime = TimeToString(Next_News_Time_High + Minutes_After_High_News * 60, TIME_MINUTES);
        }
        else if (MinSinceHighNews <= Minutes_After_High_News)
        {
            NewsTime = true;
            NewsImportance = "High";
            NewsStartTime = TimeToString(Previous_News_Time_High - Minutes_Before_High_News * 60, TIME_MINUTES);
            NewsEndTime = TimeToString(Previous_News_Time_High + Minutes_After_High_News * 60, TIME_MINUTES);
        }
    }
    
    return(NewsTime);
}





void AddToNewsArray(MqlCalendarEvent &event, MqlCalendarValue &value)
{
   int size = ArraySize(NewsArray) / ArrayRange(NewsArray, 1);
   
   
   
   int Event_Importance = event.importance;
   
   datetime NewsTime = value.time;
   
   string Importance = "High";
   
   string News_Start_Time = TimeToString(NewsTime - Minutes_Before_High_News * 60, TIME_MINUTES);
   string News_End_Time = TimeToString(NewsTime + Minutes_After_High_News * 60, TIME_MINUTES);
   
   if (Event_Importance == CALENDAR_IMPORTANCE_MODERATE)
   {
      Importance = "Medium";
      //NewsStartTime = TimeToString(NewsTime - Minutes_Before_Medium_News * 60, TIME_MINUTES);
      //NewsEndTime = TimeToString(NewsTime + Minutes_After_Medium_News * 60, TIME_MINUTES);
      News_Start_Time = TimeToString(NewsTime - Minutes_Before_Medium_News * 60, TIME_MINUTES);
      News_End_Time = TimeToString(NewsTime + Minutes_After_Medium_News * 60, TIME_MINUTES);
   }
   else if (Event_Importance == CALENDAR_IMPORTANCE_LOW)
   {
      Importance = "Low";
      //NewsStartTime = TimeToString(NewsTime - Minutes_Before_Low_News * 60, TIME_MINUTES);
      //NewsEndTime = TimeToString(NewsTime + Minutes_After_Low_News * 60, TIME_MINUTES);
      News_Start_Time = TimeToString(NewsTime - Minutes_Before_Low_News * 60, TIME_MINUTES);
      News_End_Time = TimeToString(NewsTime + Minutes_After_Low_News * 60, TIME_MINUTES);
   }
   
   string timeString=TimeToString(NewsTime, TIME_DATE|TIME_SECONDS);
   for(int k=0; k<=size-1; k++){
       if(NewsArray[k, 0]==timeString && NewsArray[k, 1]==event.name && NewsArray[k, 2] ==Importance )
         return;
   }

   ArrayResize(NewsArray, size + 1);

   NewsArray[size, 0] = timeString;
   NewsArray[size, 1] = event.name;
   NewsArray[size, 2] = Importance;
   NewsArray[size, 3] = News_Start_Time + " to " + News_End_Time;
}


bool TradeTime=true;
void ShowNewsInfo (int Y_Start)
{
   TradeTime=true;
   RemoveObjects(NewsPrefix);
   
   int Y = Y_Start;
   
   int numberOfFutureNewsToShow=(int)MathCeil(Max_Line_Of_News*(FutureNewsLine/100));
   int numberOfPastNewsToShow=Max_Line_Of_News-numberOfFutureNewsToShow;
   int countFutureNews=0;
   int countPastNews=0;
   
   int size = ArraySize(NewsArray) / ArrayRange(NewsArray, 1);
   
   for (int i = 0 ; i < size ; i ++)
   {
        datetime newsTime = StringToTime(NewsArray[i, 0]); 
        string Importance = NewsArray[i, 2];
     
        string importanceStars="";

        if(Importance=="High"){
            if(newsTime <= TimeCurrent()-News_display_minutes_before_current_time_High*60 && newsTime >= TimeCurrent()+News_display_minutes_after_current_time_High*60){
                NewsArray[i, 0]="";
                continue;
            }
        }else if(Importance=="Medium"){
            if(newsTime <= TimeCurrent()-News_display_minutes_before_current_time_Medium*60 && newsTime >= TimeCurrent()+News_display_minutes_after_current_time_Medium*60){
                NewsArray[i, 0]="";
                continue;
        }
        }else if(Importance=="Low"){
            if(newsTime <= TimeCurrent()-News_display_minutes_before_current_time_Low*60 && newsTime >= TimeCurrent()+News_display_minutes_after_current_time_Low*60){
                NewsArray[i, 0]="";
                continue;
            }
        }

      /////////////
      if(newsTime>TimeCurrent()) countFutureNews++;
      else if(newsTime <= TimeCurrent()) countPastNews++;
   }
   if(countFutureNews < numberOfFutureNewsToShow){
      numberOfFutureNewsToShow = countFutureNews;
      numberOfPastNewsToShow = Max_Line_Of_News-numberOfFutureNewsToShow;
      numberOfPastNewsToShow = (int)MathMin(numberOfPastNewsToShow, countPastNews);
   }
   int startNewsPosition=0;
   if(countPastNews>numberOfPastNewsToShow) startNewsPosition=countPastNews-numberOfPastNewsToShow;

   //sort NewsArray past to future
   datetime minTime;
   string temp="";
   for (int i = 0 ; i < size-1 ; i ++){
      for(int j =i+1; j< size; j++)
      {
         datetime newsTimeI = StringToTime(NewsArray[i, 0]); 
         datetime newsTimeJ = StringToTime(NewsArray[j, 0]);
         if((NewsArray[i, 0]==""&& NewsArray[j, 0]!="")||newsTimeI>newsTimeJ){
            temp=NewsArray[i, 0];
            NewsArray[i, 0]=NewsArray[j, 0];
            NewsArray[j, 0]=temp;
            
            temp=NewsArray[i, 1];
            NewsArray[i, 1]=NewsArray[j, 1];
            NewsArray[j, 1]=temp;
            
            temp=NewsArray[i, 2];
            NewsArray[i, 2]=NewsArray[j, 2];
            NewsArray[j, 2]=temp;
            
            temp=NewsArray[i, 3];
            NewsArray[i, 3]=NewsArray[j, 3];
            NewsArray[j, 3]=temp;
         }
      }
   }
   
   int countFutureNewsOnChart=0;
   int countPastNewsOnChart=0;
   for (int i = startNewsPosition ; i < size ; i ++)
   {
     string name = NewsPrefix + (string)i;
     
      MqlDateTime  dt_struct;   
      
      datetime newsTime = StringToTime(NewsArray[i, 0]); 
      
      
      TimeToStruct(newsTime, dt_struct);
      string dateTimeFormated=dt_struct.day+"/"+dt_struct.mon+" "+ TimeToString(newsTime,TIME_MINUTES);
     
     string Importance = NewsArray[i, 2];
     
     string importanceStars="";
     color newsColor=High_Impact_Color;
     bool InEffect=false;

     if(Importance=="High"){
         if(News_display_minutes_before_current_time_High == 0 && News_display_minutes_after_current_time_High == 0)
            continue;
         if(newsTime <= TimeCurrent()-News_display_minutes_before_current_time_High*60 && newsTime >= TimeCurrent()+News_display_minutes_after_current_time_High*60)
            continue;
         importanceStars="***";
         newsColor=High_Impact_Color;
         if(TimeCurrent() > newsTime - Minutes_Before_High_News*60 && TimeCurrent() < newsTime+Minutes_After_High_News*60)
            InEffect=true;
     }else if(Importance=="Medium"){
         if(News_display_minutes_before_current_time_Medium == 0 && News_display_minutes_after_current_time_Medium == 0)
            continue;
         if(newsTime <= TimeCurrent()-News_display_minutes_before_current_time_Medium*60 && newsTime >= TimeCurrent()+News_display_minutes_after_current_time_Medium*60)
            continue;
         importanceStars="**";
         newsColor=Medium_Impact_Color;
         if(TimeCurrent() > newsTime - Minutes_Before_Medium_News*60 && TimeCurrent() < newsTime+Minutes_After_Medium_News*60)
            InEffect=true;
     }else if(Importance=="Low"){
         if(News_display_minutes_before_current_time_Low == 0 && News_display_minutes_after_current_time_Low == 0)
            continue;
         if(newsTime <= TimeCurrent()-News_display_minutes_before_current_time_Low*60 && newsTime >= TimeCurrent()+News_display_minutes_after_current_time_Low*60)
            continue;
         importanceStars="*";
         newsColor=Low_Impact_Color;
         if(TimeCurrent() > newsTime - Minutes_Before_Low_News*60 && TimeCurrent() < newsTime+Minutes_After_Low_News*60)
            InEffect=true; 
     }
     
     if(newsTime<=TimeCurrent()){
            countPastNewsOnChart++;
      }else{
            if(countPastNewsOnChart+countFutureNewsOnChart>=Max_Line_Of_News) break;
            else countFutureNewsOnChart++;
      }
      

     
     //string text = NewsArray[i, 0] + "   " + NewsArray[i, 1] + "   " +  NewsArray[i, 2] + "   " +  NewsArray[i, 3];
     string text = dateTimeFormated + "   " + NewsArray[i, 1] ;
     if(StringLen(text) > 63 - StringLen(" " +  importanceStars + " " +  NewsArray[i, 3]) )
        text=StringSubstr(text, 0, 63 - StringLen(" " +  importanceStars + " " +  NewsArray[i, 3]));
     text =text + " " +  importanceStars + " " +  NewsArray[i, 3];
  //   if(countPastNewsOnChart==1 && countFutureNewsOnChart==1){
  //   int once_line=0;
     if(countFutureNewsOnChart==1) {
        MqlDateTime  dt_struct2;   
        TimeToStruct(TimeCurrent(), dt_struct2);
        string currentDateTimeFormated=dt_struct2.day+"/"+dt_struct2.mon+" "+ TimeToString(TimeCurrent(),TIME_MINUTES);
     
        Y += 20;
        ObjectCreate(name+"___", OBJ_LABEL, 0, 0, 0, 0, 0);
        ObjectSetInteger(0, name+"___", OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, name+"___", OBJPROP_YDISTANCE, Y);
        ObjectSetString(0, name+"___", OBJPROP_TEXT, currentDateTimeFormated+"   ------------------------------------------------------------------------");
        ObjectSetInteger(0, name+"___", OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, name+"___", OBJPROP_FONT, "Arial Black"); 
        ObjectSetInteger(0, name+"___", OBJPROP_COLOR, clrWhite);
    //    once_line +=1;
     }
     
     Y += 20;

     ObjectCreate(name, OBJ_LABEL, 0, 0, 0, 0, 0);
     ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
     ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Y);
     ObjectSetString(0, name, OBJPROP_TEXT, text);
     ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
     ObjectSetString(0, name, OBJPROP_FONT, "Arial Black"); //"Wingdings");//
     ObjectSetInteger(0, name, OBJPROP_COLOR, newsColor);
     
     if(InEffect) TradeTime=false;

     if(InEffect){
         uint w,h;
         TextSetFont("Arial Black",-100);
         TextGetSize(text,w,h);
         ObjectCreate(name+"_blinking_tick", OBJ_LABEL, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, name+"_blinking_tick", OBJPROP_XDISTANCE, 10+w+5);
         ObjectSetInteger(0, name+"_blinking_tick", OBJPROP_YDISTANCE, Y);
         ObjectSetString(0, name+"_blinking_tick", OBJPROP_TEXT, "✓");
         ObjectSetInteger(0, name+"_blinking_tick", OBJPROP_FONTSIZE, 10);
         ObjectSetString(0, name+"_blinking_tick", OBJPROP_FONT, "Arial Black"); 
         ObjectSetInteger(0, name+"_blinking_tick", OBJPROP_COLOR, clrRed);
     }
   }
   ChartRedraw();
}

void OnTimer() 
{ 



    if (!MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_OPTIMIZATION) ) int total_events=news.update();
    
    
    if (Use_News_Filter) //check news
    CheckNews();    
        
    int News_Y = 0;        
    
    if (Use_News_Filter)
    ShowNewsInfo(News_Y);




   int obj_total=ObjectsTotal();
   bool blinking_tick_redraw=false;
   for(int i=obj_total-1;i>=0;i--)
     {
      string name=ObjectName(0, i); 
      if(StringFind(name, "blinking_tick")>-1) {
            if(ObjectGetInteger(0, name, OBJPROP_COLOR)!=clrWhite){
            //if(currentColor==clrRed){
                ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
                //currentColor=clrWhite;
            }else{
                ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
                    //currentColor=clrRed;
            }
            blinking_tick_redraw=true;
      }
     }
   if(blinking_tick_redraw) ChartRedraw();
}

void RemoveObjects(string Prefix)
{
    string Name;
    for (int i = ObjectsTotal() - 1; i >= 0; i--)
    {
        Name = ObjectName(i);
        if (StringFind(Name, Prefix, 0) != -1)
            ObjectDelete(Name);
    }
}



bool ObjectCreate(string name, ENUM_OBJECT type, int window, datetime time1, double price1, datetime time2 = 0, double price2 = 0, datetime time3 = 0, double price3 = 0)
{
    return(ObjectCreate(0, name, type, window, time1, price1, time2, price2, time3, price3));
}
bool ObjectDelete(string name)
{
    return(ObjectDelete(0, name));
}
string ObjectDescription(string name)
{
    return(ObjectGetString(0, name, OBJPROP_TEXT));
}
int ObjectFind(string name)
{
    return(ObjectFind(0, name));
}
double ObjectGet(string name, ENUM_OBJECT_PROPERTY_INTEGER index)
{
    return((double) ObjectGetInteger(0, name, index));
}
string ObjectGetFiboDescription(string name, int index)
{
    return(ObjectGetString(0, name, OBJPROP_LEVELTEXT, index));
}
int ObjectGetShiftByValue(string name, double value)
{
    return(iBarShift(Symbol(), PERIOD_CURRENT, ObjectGetTimeByValue(0, name, value)));
}
double ObjectGetValueByShift(string name, int shift)
{
    return(ObjectGetValueByTime(0, name, iTime(Symbol(), PERIOD_CURRENT, shift), 0));
}
bool ObjectMove(string name, int point, datetime time1, double price1)
{
    return(ObjectMove(0, name, point, time1, price1));
}
string ObjectName(int index)
{
    return(ObjectName(0, index));
}
int ObjectsDeleteAll(int window = EMPTY, int type = EMPTY)
{
    return(ObjectsDeleteAll(0, window, type));
}
bool ObjectSet(string name, ENUM_OBJECT_PROPERTY_INTEGER index, int value)
{
    return(ObjectSetInteger(0, name, index, value));
}
bool ObjectSetFiboDescription(string name, int index, string text)
{
    return(ObjectSetString(0, name, OBJPROP_LEVELTEXT, index, text));
}
bool ObjectSetText(string name, string text, int font_size, string font = "", color text_color = CLR_NONE)
{
    int tmpObjType = ObjectType(name);
    if (tmpObjType != OBJ_LABEL && tmpObjType != OBJ_TEXT)
        return(false);
    if (StringLen(text) > 0 && font_size > 0)
    {
        if (ObjectSetString(0, name, OBJPROP_TEXT, text) == true && ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size) == true)
        {
            if ((StringLen(font) > 0) && ObjectSetString(0, name, OBJPROP_FONT, font) == false)
                return(false);
            if (ObjectSetInteger(0, name, OBJPROP_COLOR, text_color) == false)
                return(false);
            return(true);
        }
        return(false);
    }
    return(false);
}
int ObjectsTotal(int type = EMPTY, int window = -1)
{
    return(ObjectsTotal(0, window, type));
}
int ObjectType(string name)
{
    return((int) ObjectGetInteger(0, name, OBJPROP_TYPE));
}



bool KeyWordExists(string &keywords_array[], string news_name)
{
   int size = ArraySize(keywords_array);
   string nameToLower=news_name;
   StringToLower(nameToLower);
   for (int i = 0 ; i < size ; i ++)
   {
      string keywords_array_i_ToLower=keywords_array[i];
      StringToLower(keywords_array_i_ToLower);
      if (StringFind(nameToLower, keywords_array_i_ToLower, 0) != -1)
      {
         return(true);
      }
   }
   
   return(false);
}



//==== news by M ======================================================================================
