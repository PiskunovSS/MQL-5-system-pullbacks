//+------------------------------------------------------------------+
//|                                              WriteDataToFile.mq5 |
//|                                  Blog: http://tol64.blogspot.com |
//|            Copyright 2012, https://login.mql5.com/ru/users/tol64 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2012, tol64"
#property link        "https://login.mql5.com/ru/users/tol64"
#property description "email: hello.tol64@gmail.com"
#property version     "1.00"
#property script_show_inputs
//---
#define nmf __FUNCTION__+": " // ���������������� ����� ������� ����� ���������� � ������
//---
// ���������������� � ������� ����������� ��������
#define BC if(curr_mwatch==CURRENT) { break; } if(curr_mwatch==MARKETWATCH || curr_mwatch==ALL_LIST_SYMBOLS) { continue; }
//---
#define TRM_DP TerminalInfoString(TERMINAL_DATA_PATH) // �����, � ������� �������� ������ ���������
//---
//_________________________________
// ������������_��������_����������
enum FORMAT_HEADERS
  {
   NSDT_5 = 0, // "Date" "Time" "Open" "High" "Low" "Close" "Volume"
   NSDT_6 = 1, // Date,Open,High,Low,Close,Volume
   CSV_1C = 3  // CSV ��� 1�
  };
//---
//___________________________
// ������������_��������_����
enum FORMAT_DATETIME
  {
   SEP_POINT1 = 0, // dd.mm.yyyy hh:mm
   SEP_POINT2 = 1, // dd.mm.yyyy, hh:mm
   SEP_SLASH1 = 2, // dd/mm/yyyy hh:mm
   SEP_SLASH2 = 3, // dd/mm/yyyy, hh:mm
   SEP_1c1    = 4, // yyyy.mm.dd hh:mm
   SEP_1c2    = 5  // yyyymmddhhmm
  };
//---
//____________________________
// ������������_�������_������
enum CURRENT_MARKETWATCH
  {
   CURRENT          = 0, // ONLY CURRENT SYMBOLS
   MARKETWATCH      = 1, // MARKETWATCH SYMBOLS
   ALL_LIST_SYMBOLS = 2  // ALL LIST SYMBOLS
  };
//---
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �������_���������                                                |
//+------------------------------------------------------------------+
input datetime            start_date     = D'01.01.2011'; // Start Date
input datetime            end_date       = D'10.03.2016'; // End Date
input FORMAT_HEADERS      format_headers = NSDT_5;        // Format Headers
input FORMAT_DATETIME     format_date    = SEP_POINT2;    // Format Datetime
input CURRENT_MARKETWATCH curr_mwatch    = CURRENT;       // Mode Write Symbols
input bool                clear_mwatch   = true;          // Clear Market Watch
input bool                show_progress  = true;          // Show Progress (%)
//---
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ����������_����������_�_�������                                  |
//+------------------------------------------------------------------+
MqlRates rates[]; // ������ ��� ����������� ������
//---
string symbols[]; // ������ ��������
//---
// ������ ��� ����������� ��������
string arr_nmobj[22]=
  {
   "fon","hd01",
   "nm01","nm02","nm03","nm04","nm05","nm06","nm07","nm08","nm09","nm10",
   "nm11","nm12","nm13","nm14","nm15","nm16","nm17","nm18","nm19","nm20"
  };
//---
// ������ ������������� ������ ������������ ���������
string arr_txtobj[21];
//---
string path="";         // ���� � �����
int cnt_symb=0;         // ���������� ��������
int sz_arr_symb=0;      // ������ ������� ��������
int bars=0;             // ���������� ����� �� ���������� ��
int copied_bars=0;      // ���������� ������������� ����� ��� ������
double pgs_pcnt=0;      // �������� ������
double pgs_pcnt_prev=0; // �������� ������ - ���������� ��������, ��� ������ ������ �����
int hFl=INVALID_HANDLE; // ����� �����
//---
string   // ���������� ��� �������������� ����
sdt="",  // ������ � �����
dd="",   // �����
mm="",   // �����
yyyy="", // ���
tm="",   // �����
sep="";  // �����������
//---
int max_bars=0; // ������������ ���������� ����� � ���������� ���������
//---
datetime
first_date=0,        // ������ ��������� ���� � ��������� �������
first_termnl_date=0, // ������ ��������� ���� � ���� ������ ���������
first_server_date=0, // ������ ��������� ���� � ���� ������ �������
check_start_date=0;  // ����������� ���������� �������� ����
//---
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ������ >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> |
//+------------------------------------------------------------------+
void OnStart()
  {
// ���� ��������� �������� ������������� �����������,
// ������� ��������� �� ������ � ������� ���������
   if(ValidationParameters()) { return; }
//---
   max_bars=TerminalInfoInteger(TERMINAL_MAXBARS); // ������� ��������� ���������� ����� � ����
//---
   GetSymbolsToArray(); // �������� ������ �������� �������
   sz_arr_symb=ArraySize(symbols); // ������� ������ ������� ��������
//---
   SetSeparateForFormatDate(); // ��������� ����������� ��� ������� ����
//---
// ������ �� ���� �������� � ������� �� ������ � ����
   for(int s=0; s<=sz_arr_symb-1; s++)
     {
      copied_bars=0; // ������� ���������� ������������� ����� ��� ������
      pgs_pcnt=0.0; // ������� ���������� ��������� ������ ������ �������
      pgs_pcnt_prev=0.0;
      //---
      InfoTable(s); ChartRedraw();
      //---
      // ������� ������ �������� �������
      int res=GetDataCurrentSymbol(s);
      //---
      if(res==0) { BC } // ���� ����, �� ��������� ���� ���� ��������� � ��������� ��������
      //---
      if(res==2) // ���������� ��������� �������� �������������
        {
         DelAllScriptObjects(); // ������� ������� � �������, ������� ������ ������
         //---
         Print("------\n������������ ������ ������!"); break;
        }
      //---
      // ������� ���� ��� �������� ����� � �������� ���������� ��� ���
      // ���� ������ ������, ��������� ���� ���� ��������� � ��������� ��������
      if((path=CheckCreateGetPath(s))=="") { BC }
      //---
      WriteDataToFile(s); // ������� ������ � ����
     }
//---
// ��� ������������� ������� ������� �� ���� ����� �����
   DelSymbolsFromMarketWatch();
//---
// ������� ������� � �������, ������� ������ ������
   Sleep(1000); DelAllScriptObjects();
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ��������_������������_����������                                 |
//+------------------------------------------------------------------+
bool ValidationParameters()
  {
   if(start_date>=end_date)
     {
      MessageBox("��������� ���� ������ ���� ������ ��������!\n\n"
                 "��������� �� ����� ���������� ������. ���������� ��� ���.",
                 //---
                 "������ � ����������!",MB_ICONERROR);
      //---
      return(true);
     }
//---
   if(format_headers==NSDT_5 && 
      (format_date==SEP_POINT1 || format_date==SEP_SLASH1))
     {
      MessageBox("��� ���������� �������:\n\n"
                 "\"Date\" ""\"Time\" ""\"Open\" ""\"High\" ""\"Low\" ""\"Close\" ""\"Volume\"\n\n"
                 "������ ����/������� ����� ���������� ����� �� ����:\n\n"
                 "dd.mm.yyyy, hh:mm\n"
                 "dd/mm/yyyy, hh:mm\n\n"
                 "��������� �� ����� ���������� ������. ���������� ��� ���.",
                 //---
                 "�������������� �������� ���������� � ����/�������!",MB_ICONERROR);
      //---
      return(true);
     }
//---
   if(format_headers==NSDT_6 && 
      (format_date==SEP_POINT2 || format_date==SEP_SLASH2))
     {
      MessageBox("��� ���������� �������:\n\n"
                 "Date,Open,High,Low,Close,Volume\n\n"
                 "������ ����/������� ����� ���������� ����� �� ����:\n\n"
                 "dd.mm.yyyy hh:mm\n"
                 "dd/mm/yyyy hh:mm\n\n"
                 "��������� �� ����� ���������� ������. ���������� ��� ���.",
                 //---
                 "�������������� �������� ���������� � ����/�������!",MB_ICONERROR);
      //---
      return(true);
     }
//---
   return(false);
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �������_�������_��_����_�����_�����                              |
//+------------------------------------------------------------------+
void DelSymbolsFromMarketWatch()
  {
   if(clear_mwatch) // ���� ����� ������� "������" ������� �� ���� ����� �����
     {
      for(int s=0; s<=sz_arr_symb-1; s++)
        {
         if(s==0) { Print("------"); }
         //---
         if(!SymbolSelect(symbols[s],false))
           { Print("������ � �������� "+symbols[s]+" ������. ������ ��������� � ���� ����� �����."); }
        }
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ���������_������_��������_�������                                |
//+------------------------------------------------------------------+
void GetSymbolsToArray()
  {
// ���� ����� ������ ������ �������� �������
   if(curr_mwatch==CURRENT)
     { ArrayResize(symbols,1); symbols[0]=_Symbol; }
//---
// ���� ����� ������ ���� �������� �� ���� "����� ����� (MarketWatch)" ���
// ����� ������ ��������
   if(curr_mwatch==MARKETWATCH || curr_mwatch==ALL_LIST_SYMBOLS)
     {
      // ������� ���������� �������� � ���� "����� ����� (MarketWatch)"
      cnt_symb=SymbolsTotal(MWatchOrAllList());
      //---
      for(int i=0; i<=cnt_symb-1; i++)
        {
         string nm_symb="";
         //---
         ArrayResize(symbols,i+1); // �������� ������ ������� ��� �� ����
         //---
         // ������� ��� ������� �� ���� "����� ����� (MarketWatch)"
         nm_symb=SymbolName(i,MWatchOrAllList());
         symbols[i]=nm_symb; // ������ ��� ������� � ������
        }
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ���������_��_����_�����_�����_���_��_�����_������                |
//+------------------------------------------------------------------+
bool MWatchOrAllList()
  {
   if(curr_mwatch==MARKETWATCH) { return(true); }
   if(curr_mwatch==ALL_LIST_SYMBOLS) { return(false); }
//---
   return(true);
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ���������_�����������_���_�������_����                           |
//+------------------------------------------------------------------+
void SetSeparateForFormatDate()
  {
   switch(format_date)
     {
      case SEP_POINT1 : case SEP_POINT2 : sep="."; break; // ����������� �����
      case SEP_SLASH1 : case SEP_SLASH2 : sep="/"; break; // ����������� ����� ����� (���� (slash))
      case SEP_1c1 : sep="."; break; // ����������� �����
      case SEP_1c2 : sep=""; break; // ��� �������������
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �������_������_��������                                          |
//+------------------------------------------------------------------+
int GetDataCurrentSymbol(int s)
  {
   Print("------\n�"+IS(s+1)+" >>>"); // ������� � ������ ����� �������
//---
// ��������� � ��������� ������ ���������� ����������� ������
   int res=CheckLoadHistory(s,_Period);
//---
   InfoTable(s); ChartRedraw(); // ������� ������ � �������������� �������
//---
   switch(res)
     {
      case -1 : Print("����������� ������ "+symbols[s]+" (code: -1)!");                         return(0);
      case -2 :
         Print("����������� ����� ������, ��� ����� ���������� �� ������� (code: -2)!...\n"
               "...����� ������������ ��� ������ ������� ������ ������� ��������.");            break;
      //---
      case -3 : Print("���������� ���� �������� ������������� (code: -3)!");                    return(2);
      case -4 : Print("�������� ���������� �������� (code: -4)!");                              return(0);
      case  0 : Print("��� ������ ������� ��������� (code: 0).");                               break;
      case  1 : Print("��� ��������� ������ � ��������� ���������� (code: 1).");                break;
      case  2 : Print("��������� ��������� �� ��������� ������ ��������� (code: 2).");          break;
      //---
      default : Print("��������� ���������� �� ���������!");
     }
//---
// ��������� ������ � ������
   if(CopyRates(symbols[s],_Period,check_start_date,end_date,rates)<=0)
     { Print("������ ����������� ������ ������� "+symbols[s]+" - ",ErrorDesc(Error())+""); return(0); }
   else
     {
      copied_bars=ArraySize(rates); // ������� ������ �������
      //---
      Print("Symbol: ",symbols[s],"; Timeframe: ",gStrTF(_Period),"; Copied bars: ",copied_bars);
     }
//---
   return(1); // ����� 1, ���� ������ �������
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ���������_�_���������_������_����������_�����������_������       |
//+------------------------------------------------------------------+
int CheckLoadHistory(int s,ENUM_TIMEFRAMES period)
  {
   datetime times[100]; // ������ ��� ����������� �������� ������
//---
// ��������� � ��������� ������ � ���� ����� �����, ���� ��� ��� ���
   if(!SymbolInfoInteger(symbols[s],SYMBOL_SELECT))
     {
      if(Error()==ERR_MARKET_UNKNOWN_SYMBOL)
        { return(-1); } // ���������� -1, ���� ������ "����������� ������"
      //---
      SymbolSelect(symbols[s],true); // ������� ������ � ���� ����� �����
     }
//---
// �������� �� ��� ��������� ���������� �������
   SeriesInfoInteger(symbols[s],period,SERIES_FIRSTDATE,first_date); // ������ ������ ���� �������
//---
   if(first_date>0 && first_date<=start_date) { check_start_date=start_date; return(1); } // ����� 1, ���� ������� ���������� ��� ������
//---
// ���� ����� �� ����� �����, �� ������ ������� ������������
// ������ ��������� ����, ��� ������� �������� �������� ������
   if(SeriesInfoInteger(symbols[s],PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,first_termnl_date))
     {
      // ���� ������ �������
      if(first_termnl_date>0)
        {
         // �������������� ������������ ��������� ���� ����������� ������� ������� ���� ���������� ����������
         CopyTime(symbols[s],period,first_termnl_date+PeriodSeconds(period),1,times);
         //---
         // ������ ��������. ������ ������ ���� �������.
         if(SeriesInfoInteger(symbols[s],period,SERIES_FIRSTDATE,first_date))
           {
            // ���� ��������� ���� ��������� �� ��������� ������ ��������� � ������ �� ���������� ����������...
            if(first_date>0 && first_date<=start_date)
              { check_start_date=start_date; return(2); } // ...����� 2
           }
        }
     }
//________________________________________________________________
// ���� ����� �� ����� �����, �� ������ ������, ��� ���� ���������
// ����� ����������� ������� ��������� ������ � �������
//---
   int cnt_try=0,tl_try=2;
//---
// �������� ����� ������ ���� ������ � �������
   while(!SeriesInfoInteger(symbols[s],PERIOD_M1,SERIES_SERVER_FIRSTDATE,first_server_date))
     {
      if(IsStopped()) { return(-3); } // ���������� �������� �������������
      //---
      cnt_try++; // �������� �������
      //---
      Print(nmf,"��������� ����������. ��������� �������� ��������� ������� ������� ["+symbols[s]+"] (�������: "+IS(cnt_try)+"/"+IS(tl_try)+")...");
      //---
      // ����� ����� ��� �������
      if(cnt_try==2) { break; } Sleep(1000);
     }
//---
   Print("����� ������ ���� ������ �� �������: ",first_server_date);
//---
// ���� �� ������� ���� ������ ������, ��� ���� ���������, ��...
   if(first_server_date>start_date)
     { check_start_date=first_server_date; } // ...�������� �� (�������� ����� ������� ����)
//---
// ���� ��� ��������� ������ � ���� ������ ��������� ������, ��� �� �������
   if(first_date>0 && first_date<first_server_date) // ������� ��������� �� ����
     {
      Print("��������! � ���� ������ ��������� ������ ������, ��� �� �������.\n",
            "����� ������ ���� ������ �� �������: ",first_server_date,".\n",
            "����� ������ ���� ������ � ���� ������ ���������: ",first_termnl_date);
     }
//---
// ���������� �������� �� 100 ����� �� ��������� ��������� ����
   cnt_try=0; // ������� ������� �������
//---
// ���� ����� ����������� �� ��� ��� ���� �� ��������� ������������...
   while(!IsStopped()) // ...���� ������� �� ����� ���������� � ���� �����
     {
      // ��������� ���� ������� �� ����� ����������������
      while(!SeriesInfoInteger(symbols[s],period,SERIES_SYNCHRONIZED))
        {
         if(IsStopped()) { return(-3); } // ���������� �������� �������������
         //---
         bool flg_msg=false;
         if(!flg_msg) { Print(nmf,"��������� ����������. ������� ������������� �������..."); flg_msg=true; }
         Sleep(1000);
        }
      //---
      // ������� ���������� ����� �� ���������� ����������
      bars=Bars(symbols[s],period);
      //---
      if(bars>0) // ���� ���� ���������, ��...
        {
         // ...���� ����� ���������� ������� ������, ...
         // ��� ����������� � ����� ��������� "����. ���������� ����� � ����"...
         if(bars>=max_bars)
           {
            // ������������� ����, � ������� ����� ���������� ������
            datetime time_fb[];
            //---
            // ������� ������ ��������� ���� � ������� �
            CopyTime(symbols[s],period,bars,1,time_fb);
            check_start_date=time_fb[0];
            //---
            return(-2); // ... ����� -2
           }
         //---
         // �������� ����� ������ ���� �� ���������� �������
         if(SeriesInfoInteger(symbols[s],period,SERIES_FIRSTDATE,first_date))
           {
            // ���� ���� ������ ���� ����� ��������� ��������� ���� � ���������� �������...
            if(first_date>0 && first_date<=check_start_date) { return(0); } // ...����� 0
           }
        }
      //---
      // ���� ����� �� ����� �����, �� ������, ��� ������ ���� ������������� ����������
      // �������� ����� ������ ������� � 100 ����� � ��������� ������� �� ���������� ���������� ���� ��� ������� bars
      int copied=CopyTime(symbols[s],period,bars,100,times);
      //---
      if(copied>0) // ���� ������ ������
        {
         // �������� ������
         // ���� ����� ������� ���������� ���� ������ ������ ���� ����� ���������� ����������...
         if(times[0]<=check_start_date) { return(0); } // ...����� 0
         //---
         // ���� ���������� (�����+������������� ����������) ������ ���� �����...
         // ...���������� ���������� � ����� ��������� "����. ���������� ����� � ����"
         if(bars+copied>=max_bars)
           {
            // ������������� ����, � ������� ����� ���������� ������
            datetime time_fb[];
            CopyTime(symbols[s],period,max_bars,1,time_fb);
            check_start_date=time_fb[0];
            //---
            return(-2); // ...����� -2
           }
         //---
         cnt_try=0;
        }
      else // ���� ������ ���������� ��������, ��...
        {
         // ...�������� ������� ��������� �������
         cnt_try++;
         //---
         // ���� ��� ���� 2 �������, ��...
         if(cnt_try>=1) { return(-4); } // ...����� -4
         //---
         Print(nmf,"��������� ����������. ��� ������� �������� ������..."); Sleep(1000);
        }
     }
//---
// ���������� ���� �������� �������������
   return(-3);
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �������_������_�_����                                            |
//+------------------------------------------------------------------+
void WriteDataToFile(int s)
  {
// ���������� ������ � ���� ������� ����� �������
   int dgt=(int)SymbolInfoInteger(symbols[s],SYMBOL_DIGITS);
//---
   string nm_fl=path+symbols[s]+"_"+gStrTF(_Period)+".csv"; // ��� �����
//---
// ������� ����� ����� ��� ������
   hFl=FileOpen(nm_fl,FILE_WRITE|FILE_CSV|FILE_ANSI,',');
//---
   if(hFl>0) // ���� ����� �������
     {
      // ������� ���������
      if(format_headers==NSDT_5)
        { FileWrite(hFl,"\"Date\" ""\"Time\" ""\"Open\" ""\"High\" ""\"Low\" ""\"Close\" ""\"Volume\""); }
      //---
      if(format_headers==NSDT_6)
        { FileWrite(hFl,"Date","Open","High","Low","Close","Volume"); }
      //---
      if(format_headers==CSV_1C)
        { FileWrite(hFl,"Date","Open","High","Low","Close","Volume","Spread"); }
      //---
      // ������� ������
      for(int i=0; i<=copied_bars-1; i++)
        {
         if(IsStopped()) // ���� ���������� ��������� �������� �������������
           {
            DelAllScriptObjects(); // ������� ������� � �������, ������� ������ ������
            //---
            Print("------\n������������ ������ ������!"); break;
           }
         //---
         sdt=TSdm(rates[i].time); // ����� �������� ����
         //---
         // ���������� ���� �� ���, �����, �����, �����
         yyyy=StringSubstr(sdt,0,4);
         mm=StringSubstr(sdt,5,2);
         dd=StringSubstr(sdt,8,2);
         tm=StringSubstr(sdt,11);
         if(format_date==SEP_1c2) { tm=StringSubstr(sdt,11,2)+StringSubstr(sdt,14,2); }
         //---
         string sep_dt_tm=""; // ����������� �������� Date � Time
         //---
         // �������� ������ � ������������ � � ������ �������
         if(format_date==SEP_POINT1 || format_date==SEP_SLASH1 || format_date==SEP_1c1) { sep_dt_tm=" "; }
         if(format_date==SEP_POINT2 || format_date==SEP_SLASH2) { sep_dt_tm=","; }
         if(format_date==SEP_1c2) { sep_dt_tm=""; }
         //---
         // ��������� �� � ���� ������
         if(format_date==SEP_1c1 || format_date==SEP_1c2) {StringConcatenate(sdt,yyyy,sep,mm,sep,dd,sep_dt_tm,tm);}
         else {StringConcatenate(sdt,dd,sep,mm,sep,yyyy,sep_dt_tm,tm);};
         //---
         FileWrite(hFl,
                   sdt,// ����-�����
                   DS_dgt(rates[i].open,dgt),  // ���� ��������
                   DS_dgt(rates[i].high,dgt),  // ���� ���������
                   DS_dgt(rates[i].low,dgt),   // ���� ��������
                   DS_dgt(rates[i].close,dgt), // ���� ��������
                   IS((int)rates[i].tick_volume),// ���� �������� ������
                   IS((int)rates[i].spread)); //����� � �������
         //---
         if(show_progress)
           {
            // ������� �������� ��������� ������ ��� �������� �������
            pgs_pcnt=((int)(i+1)/copied_bars)*100;
            //---
            // ������� ������ � �������
            if(pgs_pcnt!=pgs_pcnt_prev)
              {
               InfoTable(s);
               ChartRedraw();
               pgs_pcnt_prev=pgs_pcnt;
              }
           }
        }
      //---
      FileClose(hFl); // ������� ����
     }
   else { Print("������ ��� ��������/�������� �����!"); }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ���������_����������_�_�������_������_�����_���_������           |
//+------------------------------------------------------------------+
string CheckCreateGetPath(int s)
  {
   int i=1;
   long search=-1;
   string ffname="",lpath="";
   string file="*.csv",folder="*";
   string
   root="DATA_OHLC\\",// �������� ����� ������
   fSmb=symbols[s]+"\\",// ��� �������
   fTF=gStrTF(_Period)+"\\"; // ��������� �������
//---
   bool flgROOT=false,flgSYMBOL=false;
//---
//+------------------------------------------------------------------+
//| ����_��������_�����_DATA_OHLC                                    |
//+------------------------------------------------------------------+
   lpath=folder;
   search=FileFindFirst(lpath,ffname); // ��������� ����� ������ � ����� - Metatrader 5\MQL5\Files
//---
   Print("����������: ",TRM_DP+"\\MQL5\\Files\\");
//---
// ���� ������ ����� ��������, ������ ����
   if(ffname==root)
     { flgROOT=true; Print("�������� ����� "+root+" ����������"); }
//---
   if(search!=INVALID_HANDLE) // ���� ����� ������ �������
     {
      if(!flgROOT) // ���� ������ ����� ���� ����������
        {
         // ���������� ��� ����� � ����� ������ �������� �����
         while(FileFindNext(search,ffname))
           {
            if(IsStopped()) // ���������� �������� �������������
              {
               // ������� ������� � �������, ������� ������ ������
               DelAllScriptObjects();
               //---
               Print("------\n������������ ������ ������!"); return("");
              }
            //---
            if(ffname==root) // ���� �������, �� ������ ����
              { flgROOT=true; Print("�������� ����� "+root+" ����������"); break; }
           }
        }
      //---
      FileFindClose(search); search=-1; // ������� ����� ������ �������� �����
     }
   else { Print("������ ��� ��������� ������ ������ ���� ���������� "+TRM_DP+" �����: ",ErrorDesc(Error())); }
//---
//+------------------------------------------------------------------+
//| ����_�����_�������                                               |
//+------------------------------------------------------------------+
   lpath=root+folder;
//---
// ��������� ����� ������ � �������� ����� ..\Files\DATA OHLC\
   search=FileFindFirst(lpath,ffname);
//---
// ���� ������ ����� �������� �������, ������ ����
   if(ffname==fSmb) { flgSYMBOL=true; Print("����� ������� "+fSmb+" ����������"); }
//---
   if(search!=INVALID_HANDLE) // ���� ����� ������ �������
     {
      if(!flgSYMBOL) // ���� ������ ����� ���� �� �������� �������
        {
         // ���������� ��� ����� � �������� ����� � ����� ������ ����� �������
         while(FileFindNext(search,ffname))
           {
            if(IsStopped()) // ���������� �������� �������������
              {
               // ������� ������� � �������, ������� ������ ������
               DelAllScriptObjects();
               //---
               Print("------\n������������ ������ ������!"); return("");
              }
            //---
            if(ffname==fSmb) // ���� �������, �� ������ ����
              { flgSYMBOL=true; Print("����� ������� "+fSmb+" ����������"); break; }
           }
        }
      //---
      FileFindClose(search); search=-1; // ������� ����� ������ ����� �������
     }
   else { Print("������ ��� ��������� ������ ������ ���� ���������� "+path+" �����"); }
//---
//+------------------------------------------------------------------+
//| ��_�����������_��������_��������_������_��������                 |
//+------------------------------------------------------------------+
   if(!flgROOT) // ���� ��� �������� ����� DATA_OHLC...
     {
      if(FolderCreate("DATA_OHLC")) // ...�������� �
        { Print("������� �������� ����� ..\DATA_OHLC\\"); }
      else
        { Print("������ ��� �������� �������� ����� DATA_OHLC: ",ErrorDesc(Error())); return(""); }
     }
//---
   if(!flgSYMBOL) // ���� ��� ����� �������, �������� �������� ����� ��������...
     {
      if(FolderCreate(root+symbols[s])) // ...�������� �
        {
         Print("������� ����� ������� ..\DATA_OHLC\\"+fSmb+"");
         //---
         return(root+symbols[s]+"\\"); // ����� ����, � ������� ����� ������ ���� ��� ������
        }
      else
        { Print("������ ��� �������� ����� ������� ..\DATA_OHLC\\"+fSmb+"\: ",ErrorDesc(Error())); return(""); }
     }
//---
   if(flgROOT && flgSYMBOL)
     {
      return(root+symbols[s]+"\\"); // ����� ����, � ������� ����� ������ ���� ��� ������
     }
//---
   return("");
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ��������������_������                                            |
//|------------------------------------------------------------------+
void InfoTable(int s)
  {
   int fnt_sz=8;            // ������ ������
   string fnt="Calibri";    // ����� ����������
   color clr=clrWhiteSmoke; // ����
//---
   int xH=300;
   int height_pnl=0;
   int yV1=1,yV2=12,xV1=165,xV2=335,xV3=1;
//---
   string sf="",stf="",ssf="";
   bool flg_sf=false,flg_stf=false,flg_ssf=false;
//---
   if(show_progress) { height_pnl=138; } else { height_pnl=126; }
//---
   flg_sf=SeriesInfoInteger(symbols[s],_Period,SERIES_FIRSTDATE,first_date);
   flg_stf=SeriesInfoInteger(symbols[s],PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,first_termnl_date);
   flg_ssf=SeriesInfoInteger(symbols[s],PERIOD_M1,SERIES_SERVER_FIRSTDATE,first_server_date);
//---
   if(flg_sf) { sf=TSdm(first_date); } else { sf="?"; }
   if(flg_stf) { stf=TSdm(first_termnl_date); } else { stf="?"; }
   if(flg_ssf) { ssf=TSdm(first_server_date); } else { ssf="?"; }
//---
   if(cnt_symb==0) { cnt_symb=1; }
//---
   int anchor1=ANCHOR_LEFT_UPPER,anchor2=ANCHOR_RIGHT_UPPER,corner=CORNER_LEFT_UPPER;
//---
   string path_symbol=SymbolInfoString(symbols[s],SYMBOL_PATH);
   path_symbol=StringSubstr(path_symbol,0,StringLen(path_symbol)-StringLen(symbols[s]));
//---
   arr_txtobj[0]="INFO TABLE";
   arr_txtobj[1]="Symbol (current / total) : ";
   arr_txtobj[2]=""+symbols[s]+" ("+IS(s+1)+"/"+IS(cnt_symb)+")";
   arr_txtobj[3]="Path Symbol : ";
   arr_txtobj[4]=path_symbol;
   arr_txtobj[5]="Timeframe : ";
   arr_txtobj[6]=gStrTF(_Period);
   arr_txtobj[7]="Input Start Date : ";
   arr_txtobj[8]=TSdm(start_date);
   arr_txtobj[9]="First Date (H1) : ";
   arr_txtobj[10]=sf;
   arr_txtobj[11]="First Terminal Date (M1) : ";
   arr_txtobj[12]=stf;
   arr_txtobj[13]="First Server Date (M1) : ";
   arr_txtobj[14]=ssf;
   arr_txtobj[15]="Max. Bars In Options Terminal : ";
   arr_txtobj[16]=IS(max_bars);
   arr_txtobj[17]="Copied Bars : ";
   arr_txtobj[18]=IS(copied_bars);
   arr_txtobj[19]="Progress Value Current Symbol : ";
   arr_txtobj[20]=DS(pgs_pcnt,2)+"%";
//---
   Create_Edit(0,0,arr_nmobj[0],"",corner,fnt,fnt_sz,clrDimGray,clrDimGray,345,height_pnl,xV3,yV1,2,C'15,15,15');
//---
   Create_Edit(0,0,arr_nmobj[1],arr_txtobj[0],corner,fnt,8,clrWhite,C'64,0,0',345,12,xV3,yV1,2,clrFireBrick);
//---
   Create_Label(0,arr_nmobj[2],arr_txtobj[1],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2,0);
   Create_Label(0,arr_nmobj[3],arr_txtobj[2],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2,0);
//---
   Create_Label(0,arr_nmobj[4],arr_txtobj[3],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2*2,0);
   Create_Label(0,arr_nmobj[5],arr_txtobj[4],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2*2,0);
//---
   Create_Label(0,arr_nmobj[6],arr_txtobj[5],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2*3,0);
   Create_Label(0,arr_nmobj[7],arr_txtobj[6],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2*3,0);
//---
   Create_Label(0,arr_nmobj[8],arr_txtobj[7],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2*4,0);
   Create_Label(0,arr_nmobj[9],arr_txtobj[8],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2*4,0);
//---
   Create_Label(0,arr_nmobj[10],arr_txtobj[9],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2*5,0);
   Create_Label(0,arr_nmobj[11],arr_txtobj[10],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2*5,0);
//---
   Create_Label(0,arr_nmobj[12],arr_txtobj[11],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2*6,0);
   Create_Label(0,arr_nmobj[13],arr_txtobj[12],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2*6,0);
//---
   Create_Label(0,arr_nmobj[14],arr_txtobj[13],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2*7,0);
   Create_Label(0,arr_nmobj[15],arr_txtobj[14],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2*7,0);
//---
   Create_Label(0,arr_nmobj[16],arr_txtobj[15],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2*8,0);
   Create_Label(0,arr_nmobj[17],arr_txtobj[16],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2*8,0);
//---
   Create_Label(0,arr_nmobj[18],arr_txtobj[17],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2*9,0);
   Create_Label(0,arr_nmobj[19],arr_txtobj[18],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2*9,0);
//---
   if(show_progress)
     {
      Create_Label(0,arr_nmobj[20],arr_txtobj[19],anchor2,corner,fnt,fnt_sz,clr,xV1,yV1+yV2*10,0);
      Create_Label(0,arr_nmobj[21],arr_txtobj[20],anchor2,corner,fnt,fnt_sz,clr,xV2,yV1+yV2*10,0);
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ��������_�������_LABEL                                           |
//+------------------------------------------------------------------+
void Create_Label(long   chrt_id,   // id �������
                  string lable_nm,  // ��� �������
                  string rename,    // ������������ ���
                  long   anchor,    // ����� ��������
                  long   corner,    // ���� ��������
                  string font_bsc,  // �����
                  int    font_size, // ������ ������
                  color  font_clr,  // ���� ������
                  int    x_dist,    // ���������� �� ����� X
                  int    y_dist,    // ���������� �� ����� Y
                  long   zorder)    // ���������
  {
   if(ObjectCreate(chrt_id,lable_nm,OBJ_LABEL,0,0,0)) // �������� �������
     {
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TEXT,rename);          // ��������� �����
      ObjectSetString(chrt_id,lable_nm,OBJPROP_FONT,font_bsc);        // ��������� ������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_COLOR,font_clr);      // ��������� ����� ������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ANCHOR,anchor);       // ��������� ����� ��������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_CORNER,corner);       // ��������� ����� ��������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_FONTSIZE,font_size);  // ��������� ������� ������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_XDISTANCE,x_dist);    // ��������� ���������� X
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_YDISTANCE,y_dist);    // ��������� ���������� Y
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_SELECTABLE,false);    // ������ �������� ������, ���� FALSE
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ZORDER,zorder);       // ��������� ����/����
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TOOLTIP,"\n");         // ��� ����������� ���������, ���� "\n"
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ��������_�������_EDIT                                            |
//+------------------------------------------------------------------+
void Create_Edit(long   chrt_id,       // id �������
                 int    nmb_win,       // ����� ���� (�������)
                 string lable_nm,      // ��� �������
                 string text,          // ������������ �����
                 long   corner,        // ���� ��������
                 string font_bsc,      // �����
                 int    font_size,     // ������ ������
                 color  font_clr,      // ���� ������
                 color  font_clr_brd,  // ���� ������
                 int    xsize,         // ������
                 int    ysize,         // ������
                 int    x_dist,        // ���������� �� ����� X
                 int    y_dist,        // ���������� �� ����� Y
                 long   zorder,        // ���������
                 color  clr)           // ���� ����
  {
   if(ObjectCreate(chrt_id,lable_nm,OBJ_EDIT,nmb_win,0,0)) // �������� �������
     {
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TEXT,text);                     // ��������� �����
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_CORNER,corner);                // ��������� ���� ��������
      ObjectSetString(chrt_id,lable_nm,OBJPROP_FONT,font_bsc);                 // ��������� ������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ALIGN,ALIGN_CENTER);           // ������������ �� ������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_FONTSIZE,font_size);           // ��������� ������� ������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_COLOR,font_clr);               // ���� ������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_BORDER_COLOR,font_clr_brd);    // ���� ����
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_BGCOLOR,clr);                  // ���� ����
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_XSIZE,xsize);                  // ������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_YSIZE,ysize);                  // ������
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_XDISTANCE,x_dist);             // ��������� ���������� X
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_YDISTANCE,y_dist);             // ��������� ���������� Y
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_SELECTABLE,false);             // ������ �������� ������, ���� FALSE
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ZORDER,zorder);                // ��������� ����/����
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_READONLY,true);                // ������ ��� ������
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TOOLTIP,"\n");                  // ��� ����������� ���������, ���� "\n"
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �������_���_�����������_�������_�������_������_������            |
//+------------------------------------------------------------------+
void DelAllScriptObjects()
  {
// ������� ������ ������� ��� ����������� ��������
   int sz_arr1=ArraySize(arr_nmobj);
//---
// ������ ��� �������
   for(int i=0; i<sz_arr1; i++)
     { DelObjbyName(arr_nmobj[i]);  }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �������_�������_��_�����                                         |
//+------------------------------------------------------------------+
int DelObjbyName(string Name)
  {
   int nm_obj=0;
   bool res=false;
//---
   nm_obj=ObjectFind(ChartID(),Name);
//---
   if(nm_obj>=0)
     {
      res=ObjectDelete(ChartID(),Name);
      //---
      if(!res) { Print("������ ��� �������� �������: - "+ErrorDesc(Error())+""); return(false); }
     }
//---
   return(res);
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �����������_��_DATETIME_�_STRING_�_�������_TIME_DATE             |
//+------------------------------------------------------------------+
string TSd(datetime aValue)
  {
   return(TimeToString(aValue,TIME_DATE));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �����������_��_DATETIME_�_STRING_                                |
//| �_�������_TIME_DATE|TIME_MINUTES                                 |
//+------------------------------------------------------------------+
string TSdm(datetime aValue)
  {
   return(TimeToString(aValue,TIME_DATE|TIME_MINUTES));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �����������_��_INTEGER_�_STRING                                  |
//+------------------------------------------------------------------+
string IS(int aValue)
  {
   return(IntegerToString(aValue));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �����������_��_DOUBLE_�_STRING                                   |
//+------------------------------------------------------------------+
string DS(double aValue,int amount)
  {
   return(DoubleToString(aValue,amount));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| �����������_��_DOUBLE_�_STRING_�_DIGITS_�������                  |
//+------------------------------------------------------------------+
string DS_dgt(double aValue,int digit)
  {
   return(DoubleToString(aValue,digit));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ����������_������_TIMEFRAME                                      |
//+------------------------------------------------------------------+
string gStrTF(ENUM_TIMEFRAMES TF)
  {
   string str="";
//---
   if(TF==PERIOD_CURRENT) TF=Period();
//---
   switch(TF)
     {
      case PERIOD_M1  : str="M1";  break;
      case PERIOD_M2  : str="M2";  break;
      case PERIOD_M3  : str="M3";  break;
      case PERIOD_M4  : str="M4";  break;
      case PERIOD_M5  : str="M5";  break;
      case PERIOD_M6  : str="M6";  break;
      case PERIOD_M10 : str="M10"; break;
      case PERIOD_M12 : str="M12"; break;
      case PERIOD_M15 : str="M15"; break;
      case PERIOD_M20 : str="M20"; break;
      case PERIOD_M30 : str="M30"; break;
      case PERIOD_H1  : str="H1";  break;
      case PERIOD_H2  : str="H2";  break;
      case PERIOD_H3  : str="H3";  break;
      case PERIOD_H4  : str="H4";  break;
      case PERIOD_H6  : str="H6";  break;
      case PERIOD_H8  : str="H8";  break;
      case PERIOD_H12 : str="H12"; break;
      case PERIOD_D1  : str="D1";  break;
      case PERIOD_W1  : str="W1";  break;
      case PERIOD_MN1 : str="MN1"; break;
      //---
      default : str="����������� ���������!";
     }
//---
   return(str);
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ��������_���������_���������������_������                        |
//+------------------------------------------------------------------+
int Error()
  {
   return(GetLastError());
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| RETURN_ERROR_DESCRIPTION                                         |
//+------------------------------------------------------------------+
string ErrorDesc(int error_code)
  {
   string error_string;
//----
   switch(error_code)
     {
      //--- ���� �������� ��������� �������
      case 10004: error_string=""+IS(Error())+": �������";                                                         break;
      case 10006: error_string=""+IS(Error())+": ������ ���������";                                                break;
      case 10007: error_string=""+IS(Error())+": ������ ������ ���������";                                        break;
      case 10008: error_string=""+IS(Error())+": ����� ��������";                                                  break;
      case 10009: error_string=""+IS(Error())+": ������ ���������";                                                break;
      case 10010: error_string=""+IS(Error())+": ������ ��������� ��������";                                       break;
      case 10011: error_string=""+IS(Error())+": ������ ��������� �������";                                        break;
      case 10012: error_string=""+IS(Error())+": ������ ������ �� ��������� �������";                             break;
      case 10013: error_string=""+IS(Error())+": ������������ ������";                                             break;
      case 10014: error_string=""+IS(Error())+": ������������ ����� � �������";                                    break;
      case 10015: error_string=""+IS(Error())+": ������������ ���� � �������";                                     break;
      case 10016: error_string=""+IS(Error())+": ������������ ����� � �������";                                    break;
      case 10017: error_string=""+IS(Error())+": �������� ���������";                                              break;
      case 10018: error_string=""+IS(Error())+": ����� ������";                                                    break;
      case 10019: error_string=""+IS(Error())+": ��� ����������� �������� �������";                                break;
      case 10020: error_string=""+IS(Error())+": ���� ����������";                                                 break;
      case 10021: error_string=""+IS(Error())+": ����������� ��������� ��� ��������� �������";                     break;
      case 10022: error_string=""+IS(Error())+": �������� ���� ��������� ������ � �������";                        break;
      case 10023: error_string=""+IS(Error())+": ��������� ������ ����������";                                     break;
      case 10024: error_string=""+IS(Error())+": ������� ������ �������";                                          break;
      case 10025: error_string=""+IS(Error())+": � ������� ��� ���������";                                         break;
      case 10026: error_string=""+IS(Error())+": ������������ �������� ���������";                                 break;
      case 10027: error_string=""+IS(Error())+": ������������ �������� ���������� ����������";                     break;
      case 10028: error_string=""+IS(Error())+": ������ ������������ ��� ���������";                               break;
      case 10029: error_string=""+IS(Error())+": ����� ��� ������� ����������";                                    break;
      case 10030: error_string=""+IS(Error())+": ������ ���������������� ��� ���������� ������ �� �������";        break;
      case 10031: error_string=""+IS(Error())+": ��� ���������� � �������� ��������";                              break;
      case 10032: error_string=""+IS(Error())+": �������� ��������� ������ ��� �������� ������";                   break;
      case 10033: error_string=""+IS(Error())+": ��������� ����� �� ���������� ���������� �������";                break;
      case 10034: error_string=""+IS(Error())+": ��������� ����� �� ����� ������� � ������� ��� ������� �������";  break;

      //--- ������ ������� ����������

      case 0:  // �������� ��������� �������
      case 4001: error_string=""+IS(Error())+": ����������� ���������� ������";                                                                                                   break;
      case 4002: error_string=""+IS(Error())+": ��������� �������� ��� ���������� ������ ������� ����������� ���������";                                                          break;
      case 4003: error_string=""+IS(Error())+": ��������� �������� ��� ������ ��������� �������";                                                                                 break;
      case 4004: error_string=""+IS(Error())+": ������������ ������ ��� ���������� ��������� �������";                                                                            break;
      case 4005: error_string=""+IS(Error())+": ��������� �������� ������� ����� �/��� ������������ �������� �/��� ��������� � ������ ��������� �/��� ������";                    break;
      case 4006: error_string=""+IS(Error())+": ������ ������������� ����, ������������� ������� ��� ����������� ������ ������������� �������";                                   break;
      case 4007: error_string=""+IS(Error())+": ������������ ������ ��� ����������������� ������� ���� ������� ��������� ������� ������������ �������";                           break;
      case 4008: error_string=""+IS(Error())+": ������������ ������ ��� ����������������� ������";                                                                                break;
      case 4009: error_string=""+IS(Error())+": �������������������� ������";                                                                                                     break;
      case 4010: error_string=""+IS(Error())+": ������������ �������� ���� �/��� �������";                                                                                        break;
      case 4011: error_string=""+IS(Error())+": ������������� ������ ������� ��������� 2 ���������";                                                                              break;
      case 4012: error_string=""+IS(Error())+": ��������� ���������";                                                                                                             break;
      case 4013: error_string=""+IS(Error())+": ��������� ��� ���������";                                                                                                         break;
      case 4014: error_string=""+IS(Error())+": ��������� ������� �� ��������� ��� ������";                                                                                       break;
      //-- �������
      case 4101: error_string=""+IS(Error())+": ��������� ������������� �������";                                                                                                 break;
      case 4102: error_string=""+IS(Error())+": ������ �� ��������";                                                                                                              break;
      case 4103: error_string=""+IS(Error())+": ������ �� ������";                                                                                                                break;
      case 4104: error_string=""+IS(Error())+": � ������� ��� ��������, ������� ��� �� ���������� �������";                                                                       break;
      case 4105: error_string=""+IS(Error())+": ������ �������� �������";                                                                                                         break;
      case 4106: error_string=""+IS(Error())+": ������ ��� ��������� ��� ������� ������� � �������";                                                                              break;
      case 4107: error_string=""+IS(Error())+": ��������� �������� ��� �������";                                                                                                  break;
      case 4108: error_string=""+IS(Error())+": ������ ��� �������� �������";                                                                                                     break;
      case 4109: error_string=""+IS(Error())+": ��������� ������������� �������� �������";                                                                                        break;
      case 4110: error_string=""+IS(Error())+": ������ ��� �������� ���������";                                                                                                   break;
      case 4111: error_string=""+IS(Error())+": ������ ��������� �� �������";                                                                                                     break;
      case 4112: error_string=""+IS(Error())+": ������ ��� ���������� �������";                                                                                                   break;
      case 4113: error_string=""+IS(Error())+": �������, ���������� ��������� ���������, �� �������";                                                                             break;
      case 4114: error_string=""+IS(Error())+": ������ ��� ���������� ���������� �� ������";                                                                                      break;
      case 4115: error_string=""+IS(Error())+": ������ ��� �������� ���������� � �������";                                                                                        break;
      case 4116: error_string=""+IS(Error())+": ��������� �� ������ �� ��������� �������";                                                                                        break;
      //-- ����������� �������
      case 4201: error_string=""+IS(Error())+": ������ ��� ������ � ����������� ��������";                                                                                        break;
      case 4202: error_string=""+IS(Error())+": ����������� ������ �� ������";                                                                                                    break;
      case 4203: error_string=""+IS(Error())+": ��������� ������������� �������� ������������ �������";                                                                           break;
      case 4204: error_string=""+IS(Error())+": ���������� �������� ����, ��������������� ��������";                                                                              break;
      case 4205: error_string=""+IS(Error())+": ���������� �������� ��������, ��������������� ����";                                                                              break;
      //-- MarketInfo
      case 4301: error_string=""+IS(Error())+": ����������� ������";                                                                                                              break;
      case 4302: error_string=""+IS(Error())+": ������ �� ������ � MarketWatch";                                                                                                  break;
      case 4303: error_string=""+IS(Error())+": ��������� ������������� �������� �������";                                                                                        break;
      case 4304: error_string=""+IS(Error())+": ����� ���������� ���� ���������� (����� �� ����)";                                                                                break;
      //-- ������ � �������
      case 4401: error_string=""+IS(Error())+": ������������� ������� �� �������!";                                                                                               break;
      case 4402: error_string=""+IS(Error())+": ��������� ������������� �������� �������";                                                                                        break;
      //-- Global_Variables
      case 4501: error_string=""+IS(Error())+": ���������� ���������� ����������� ��������� �� �������";                                                                          break;
      case 4502: error_string=""+IS(Error())+": ���������� ���������� ����������� ��������� � ����� ������ ��� ����������";                                                       break;
      case 4510: error_string=""+IS(Error())+": �� ������� ��������� ������";                                                                                                     break;
      case 4511: error_string=""+IS(Error())+": �� ������� ������������� ����";                                                                                                   break;
      case 4512: error_string=""+IS(Error())+": ��������� ������������� �������� ���������";                                                                                      break;
      case 4513: error_string=""+IS(Error())+": ��������� ������������� �������� ���������";                                                                                      break;
      case 4514: error_string=""+IS(Error())+": �� ������� ��������� ���� �� ftp";                                                                                                break;
      //-- ������ ���������������� �����������
      case 4601: error_string=""+IS(Error())+": ������������ ������ ��� ������������� ������������ �������";                                                                      break;
      case 4602: error_string=""+IS(Error())+": ��������� ������ ������ ������������� ������";                                                                                    break;
      //-- �������� ���������������� �����������
      case 4603: error_string=""+IS(Error())+": ��������� ������������� �������� ����������������� ����������";                                                                   break;
      //-- Account
      case 4701: error_string=""+IS(Error())+": ��������� ������������� �������� �����";                                                                                          break;
      case 4751: error_string=""+IS(Error())+": ��������� ������������� �������� ��������";                                                                                       break;
      case 4752: error_string=""+IS(Error())+": �������� ��� �������� ���������";                                                                                                 break;
      case 4753: error_string=""+IS(Error())+": ������� �� �������";                                                                                                              break;
      case 4754: error_string=""+IS(Error())+": ����� �� ������";                                                                                                                 break;
      case 4755: error_string=""+IS(Error())+": ������ �� �������";                                                                                                               break;
      case 4756: error_string=""+IS(Error())+": �� ������� ��������� �������� ������";                                                                                            break;
      //-- ����������
      case 4801: error_string=""+IS(Error())+": ����������� ������";                                                                                                              break;
      case 4802: error_string=""+IS(Error())+": ��������� �� ����� ���� ������";                                                                                                  break;
      case 4803: error_string=""+IS(Error())+": ������������ ������ ��� ���������� ����������";                                                                                   break;
      case 4804: error_string=""+IS(Error())+": ��������� �� ����� ���� �������� � ������� ����������";                                                                           break;
      case 4805: error_string=""+IS(Error())+": ������ ��� ���������� ����������";                                                                                                break;
      case 4806: error_string=""+IS(Error())+": ����������� ������ �� �������";                                                                                                   break;
      case 4807: error_string=""+IS(Error())+": ��������� ����� ����������";                                                                                                      break;
      case 4808: error_string=""+IS(Error())+": ������������ ���������� ���������� ��� �������� ����������";                                                                      break;
      case 4809: error_string=""+IS(Error())+": ����������� ��������� ��� �������� ����������";                                                                                   break;
      case 4810: error_string=""+IS(Error())+": ������ ���������� � ������� ������ ���� ��� ����������������� ����������";                                                        break;
      case 4811: error_string=""+IS(Error())+": ������������ ��� ��������� � ������� ��� �������� ����������";                                                                    break;
      case 4812: error_string=""+IS(Error())+": ��������� ������ �������������� ������������� ������";                                                                            break;
      //-- ������ ���
      case 4901: error_string=""+IS(Error())+": ������ ��� �� ����� ���� ��������";                                                                                               break;
      case 4902: error_string=""+IS(Error())+": ������ ��� �� ����� ���� ������";                                                                                                 break;
      case 4903: error_string=""+IS(Error())+": ������ ������� ��� �� ����� ���� ��������";                                                                                       break;
      case 4904: error_string=""+IS(Error())+": ������ ��� �������� �� ��������� ����� ������ ������� ���";                                                                       break;
      //-- �������� ��������
      case 5001: error_string=""+IS(Error())+": �� ����� ���� ������� ������������ ����� 64 ������";                                                                              break;
      case 5002: error_string=""+IS(Error())+": ������������ ��� �����";                                                                                                          break;
      case 5003: error_string=""+IS(Error())+": ������� ������� ��� �����";                                                                                                       break;
      case 5004: error_string=""+IS(Error())+": ������ �������� �����";                                                                                                           break;
      case 5005: error_string=""+IS(Error())+": ������������ ������ ��� ���� ������";                                                                                             break;
      case 5006: error_string=""+IS(Error())+": ������ �������� �����";                                                                                                           break;
      case 5007: error_string=""+IS(Error())+": ���� � ����� ������� ��� ��� ������, ���� �� ���������� ������";                                                                  break;
      case 5008: error_string=""+IS(Error())+": ��������� ����� �����";                                                                                                           break;
      case 5009: error_string=""+IS(Error())+": ���� ������ ���� ������ ��� ������";                                                                                              break;
      case 5010: error_string=""+IS(Error())+": ���� ������ ���� ������ ��� ������";                                                                                              break;
      case 5011: error_string=""+IS(Error())+": ���� ������ ���� ������ ��� ��������";                                                                                            break;
      case 5012: error_string=""+IS(Error())+": ���� ������ ���� ������ ��� ���������";                                                                                           break;
      case 5013: error_string=""+IS(Error())+": ���� ������ ���� ������ ��� ��������� ��� CSV";                                                                                   break;
      case 5014: error_string=""+IS(Error())+": ���� ������ ���� ������ ��� CSV";                                                                                                 break;
      case 5015: error_string=""+IS(Error())+": ������ ������ �����";                                                                                                             break;
      case 5016: error_string=""+IS(Error())+": ������ ���� ������ ������ ������, ��� ��� ���� ������ ��� ��������";                                                              break;
      case 5017: error_string=""+IS(Error())+": ��� ��������� �������� ������ ���� ��������� ����, ��� ��������� � ��������";                                                     break;
      case 5018: error_string=""+IS(Error())+": ��� �� ����, � ����������";                                                                                                       break;
      case 5019: error_string=""+IS(Error())+": ���� �� ����������";                                                                                                              break;
      case 5020: error_string=""+IS(Error())+": ���� �� ����� ���� ���������";                                                                                                    break;
      case 5021: error_string=""+IS(Error())+": ��������� ��� ����������";                                                                                                        break;
      case 5022: error_string=""+IS(Error())+": ���������� �� ����������";                                                                                                        break;
      case 5023: error_string=""+IS(Error())+": ��� ����, � �� ����������";                                                                                                       break;
      case 5024: error_string=""+IS(Error())+": ���������� �� ����� ���� �������";                                                                                                break;
      case 5025: error_string=""+IS(Error())+": �� ������� �������� ���������� (��������, ���� ��� ��������� ������ ������������� � �������� �������� �� �������)";               break;
      //-- �������������� �����
      case 5030: error_string=""+IS(Error())+": � ������ ��� ����";                                                                                                               break;
      case 5031: error_string=""+IS(Error())+": � ������ ��������� ����";                                                                                                         break;
      case 5032: error_string=""+IS(Error())+": � ������ ��������� �����";                                                                                                        break;
      case 5033: error_string=""+IS(Error())+": ������ �������������� ������ � ����";                                                                                             break;
      case 5034: error_string=""+IS(Error())+": ������������ ������ ��� ������";                                                                                                  break;
      case 5035: error_string=""+IS(Error())+": ����� ������ ������, ��� ���������";                                                                                              break;
      case 5036: error_string=""+IS(Error())+": ������� ������� �����, ������, ��� ULONG_MAX";                                                                                    break;
      case 5037: error_string=""+IS(Error())+": ��������� ��������� ������";                                                                                                      break;
      case 5038: error_string=""+IS(Error())+": ��������� �������������� ������, ��� ����������";                                                                                 break;
      case 5039: error_string=""+IS(Error())+": ���������� ������, ��� ��������� ��������������";                                                                                 break;
      case 5040: error_string=""+IS(Error())+": ����������� �������� ���� string";                                                                                                break;
      case 5041: error_string=""+IS(Error())+": ������� �� ��������� ������";                                                                                                     break;
      case 5042: error_string=""+IS(Error())+": � ����� ������ �������� 0, ����������� ��������";                                                                                 break;
      case 5043: error_string=""+IS(Error())+": ����������� ��� ������ ��� ����������� � ������";                                                                                 break;
      case 5044: error_string=""+IS(Error())+": ����������� ������ ������";                                                                                                       break;
      //-- ������ � ���������
      case 5050: error_string=""+IS(Error())+": ����������� ������������� ��������. ��������� ������ ����� ���� ���������� ������ � ���������, � �������� ������ � � ��������";   break;
      case 5051: error_string=""+IS(Error())+": �������� ������ �������� ��� AS_SERIES, � �� �������������� �������";                                                             break;
      case 5052: error_string=""+IS(Error())+": ������� ��������� ������, ��������� ������� �� ��������� �������";                                                                break;
      case 5053: error_string=""+IS(Error())+": ������ ������� �����";                                                                                                            break;
      case 5054: error_string=""+IS(Error())+": ������ ���� �������� ������";                                                                                                     break;
      case 5055: error_string=""+IS(Error())+": ������ ���� ���������� ������";                                                                                                   break;
      case 5056: error_string=""+IS(Error())+": ��������� �� ����� ���� ������������";                                                                                            break;
      case 5057: error_string=""+IS(Error())+": ������ ���� ������ ���� double";                                                                                                  break;
      case 5058: error_string=""+IS(Error())+": ������ ���� ������ ���� float";                                                                                                   break;
      case 5059: error_string=""+IS(Error())+": ������ ���� ������ ���� long";                                                                                                    break;
      case 5060: error_string=""+IS(Error())+": ������ ���� ������ ���� int";                                                                                                     break;
      case 5061: error_string=""+IS(Error())+": ������ ���� ������ ���� short";                                                                                                   break;
      case 5062: error_string=""+IS(Error())+": ������ ���� ������ ���� char";                                                                                                    break;
      //-- ���������������� ������

      default: error_string="������ �� ����������!";
     }
//----
   return(error_string);
  }
//+------------------------------------------------------------------+
