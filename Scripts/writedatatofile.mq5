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
#define nmf __FUNCTION__+": " // Макроподстановка имени функции перед сообщением в журнал
//---
// Макроподстановка с выбором дальнейшего действия
#define BC if(curr_mwatch==CURRENT) { break; } if(curr_mwatch==MARKETWATCH || curr_mwatch==ALL_LIST_SYMBOLS) { continue; }
//---
#define TRM_DP TerminalInfoString(TERMINAL_DATA_PATH) // Папка, в которой хранятся данные терминала
//---
//_________________________________
// ПЕРЕЧИСЛЕНИЕ_ФОРМАТОВ_ЗАГОЛОВКОВ
enum FORMAT_HEADERS
  {
   NSDT_5 = 0, // "Date" "Time" "Open" "High" "Low" "Close" "Volume"
   NSDT_6 = 1, // Date,Open,High,Low,Close,Volume
   CSV_1C = 3  // CSV для 1С
  };
//---
//___________________________
// ПЕРЕЧИСЛЕНИЕ_ФОРМАТОВ_ДАТЫ
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
// ПЕРЕЧИСЛЕНИЕ_РЕЖИМОВ_ЗАПИСИ
enum CURRENT_MARKETWATCH
  {
   CURRENT          = 0, // ONLY CURRENT SYMBOLS
   MARKETWATCH      = 1, // MARKETWATCH SYMBOLS
   ALL_LIST_SYMBOLS = 2  // ALL LIST SYMBOLS
  };
//---
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ВНЕШНИЕ_ПАРАМЕТРЫ                                                |
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
//| ГЛОБАЛЬНЫЕ_ПЕРЕМЕННЫЕ_И_МАССИВЫ                                  |
//+------------------------------------------------------------------+
MqlRates rates[]; // Массив для копирования данных
//---
string symbols[]; // Массив символов
//---
// Массив имён графических объектов
string arr_nmobj[22]=
  {
   "fon","hd01",
   "nm01","nm02","nm03","nm04","nm05","nm06","nm07","nm08","nm09","nm10",
   "nm11","nm12","nm13","nm14","nm15","nm16","nm17","nm18","nm19","nm20"
  };
//---
// Массив отображаемого текста графическими объектами
string arr_txtobj[21];
//---
string path="";         // Путь к файлу
int cnt_symb=0;         // Количество символов
int sz_arr_symb=0;      // Размер массива символов
int bars=0;             // Количество баров по указанному ТФ
int copied_bars=0;      // Количество скопированных баров для записи
double pgs_pcnt=0;      // Прогресс записи
double pgs_pcnt_prev=0; // Прогресс записи - предыдущее значение, для вывода только новых
int hFl=INVALID_HANDLE; // Хэндл файла
//---
string   // Переменные для форматирования даты
sdt="",  // Строка с датой
dd="",   // Число
mm="",   // Месяц
yyyy="", // Год
tm="",   // Время
sep="";  // Разделитель
//---
int max_bars=0; // Максимальное количество баров в настройках терминала
//---
datetime
first_date=0,        // Первая доступная дата в указанном периоде
first_termnl_date=0, // Первая доступная дата в базе данных терминала
first_server_date=0, // Первая доступная дата в базе данных сервера
check_start_date=0;  // Проверенное корректное значение даты
//---
//____________________________________________________________________
//+------------------------------------------------------------------+
//| СКРИПТ >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> |
//+------------------------------------------------------------------+
void OnStart()
  {
// Если параметры введённые пользователем некорректны,
// выведем сообщение об ошибке и закроем программу
   if(ValidationParameters()) { return; }
//---
   max_bars=TerminalInfoInteger(TERMINAL_MAXBARS); // Получим доступное количество баров в окне
//---
   GetSymbolsToArray(); // Заполним массив символов именами
   sz_arr_symb=ArraySize(symbols); // Получим размер массива символов
//---
   SetSeparateForFormatDate(); // Определим разделитель для формата даты
//---
// Пройдём по всем символам и запишем их данные в файл
   for(int s=0; s<=sz_arr_symb-1; s++)
     {
      copied_bars=0; // Обнулим переменную скопированных баров для записи
      pgs_pcnt=0.0; // Обнулим переменную прогресса записи данных символа
      pgs_pcnt_prev=0.0;
      //---
      InfoTable(s); ChartRedraw();
      //---
      // Получим данные текущего символа
      int res=GetDataCurrentSymbol(s);
      //---
      if(res==0) { BC } // Если ноль, то прерываем цикл либо переходим к следующей итерации
      //---
      if(res==2) // Выполнение программы прервано пользователем
        {
         DelAllScriptObjects(); // Удаляем объекты с графика, которые создал скрипт
         //---
         Print("------\nПользователь удалил скрипт!"); break;
        }
      //---
      // Получим путь для создания файла и создадим директории для них
      // Если пустая строка, прерываем цикл либо переходим к следующей итерации
      if((path=CheckCreateGetPath(s))=="") { BC }
      //---
      WriteDataToFile(s); // Запишем данные в файл
     }
//---
// При необходимости удалить символы из окна Обзор Рынка
   DelSymbolsFromMarketWatch();
//---
// Удаляем объекты с графика, которые создал скрипт
   Sleep(1000); DelAllScriptObjects();
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ПРОВЕРКА_КОРРЕКТНОСТИ_ПАРАМЕТРОВ                                 |
//+------------------------------------------------------------------+
bool ValidationParameters()
  {
   if(start_date>=end_date)
     {
      MessageBox("Начальная дата должна быть раньше конечной!\n\n"
                 "Программа не может продолжить работу. Попробуйте ещё раз.",
                 //---
                 "Ошибка в параметрах!",MB_ICONERROR);
      //---
      return(true);
     }
//---
   if(format_headers==NSDT_5 && 
      (format_date==SEP_POINT1 || format_date==SEP_SLASH1))
     {
      MessageBox("Для заголовков формата:\n\n"
                 "\"Date\" ""\"Time\" ""\"Open\" ""\"High\" ""\"Low\" ""\"Close\" ""\"Volume\"\n\n"
                 "Формат даты/времени можно установить одним из двух:\n\n"
                 "dd.mm.yyyy, hh:mm\n"
                 "dd/mm/yyyy, hh:mm\n\n"
                 "Программа не может продолжить работу. Попробуйте ещё раз.",
                 //---
                 "Несоответствие форматов заголовков и даты/времени!",MB_ICONERROR);
      //---
      return(true);
     }
//---
   if(format_headers==NSDT_6 && 
      (format_date==SEP_POINT2 || format_date==SEP_SLASH2))
     {
      MessageBox("Для заголовков формата:\n\n"
                 "Date,Open,High,Low,Close,Volume\n\n"
                 "Формат даты/времени можно установить одним из двух:\n\n"
                 "dd.mm.yyyy hh:mm\n"
                 "dd/mm/yyyy hh:mm\n\n"
                 "Программа не может продолжить работу. Попробуйте ещё раз.",
                 //---
                 "Несоответствие форматов заголовков и даты/времени!",MB_ICONERROR);
      //---
      return(true);
     }
//---
   return(false);
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| УДАЛЯЕТ_СИМВОЛЫ_ИЗ_ОКНА_ОБЗОР_РЫНКА                              |
//+------------------------------------------------------------------+
void DelSymbolsFromMarketWatch()
  {
   if(clear_mwatch) // Если нужно удалить "лишние" символы из окна Обзор Рынка
     {
      for(int s=0; s<=sz_arr_symb-1; s++)
        {
         if(s==0) { Print("------"); }
         //---
         if(!SymbolSelect(symbols[s],false))
           { Print("График с символом "+symbols[s]+" открыт. Символ останется в окне Обзор Рынка."); }
        }
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ЗАПОЛНЯЕТ_МАССИВ_СИМВОЛОВ_ИМЕНАМИ                                |
//+------------------------------------------------------------------+
void GetSymbolsToArray()
  {
// Если нужны данные только текущего символа
   if(curr_mwatch==CURRENT)
     { ArrayResize(symbols,1); symbols[0]=_Symbol; }
//---
// Если нужны данные всех символов из окна "Обзор рынка (MarketWatch)" или
// всего списка символов
   if(curr_mwatch==MARKETWATCH || curr_mwatch==ALL_LIST_SYMBOLS)
     {
      // Получим количество символов в окне "Обзор рынка (MarketWatch)"
      cnt_symb=SymbolsTotal(MWatchOrAllList());
      //---
      for(int i=0; i<=cnt_symb-1; i++)
        {
         string nm_symb="";
         //---
         ArrayResize(symbols,i+1); // Увеличим размер массива ещё на один
         //---
         // Получим имя символа из окна "Обзор рынка (MarketWatch)"
         nm_symb=SymbolName(i,MWatchOrAllList());
         symbols[i]=nm_symb; // Занесём имя символа в массив
        }
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| УКАЗАТЕЛЬ_НА_ОКНО_ОБЗОР_РЫНКА_ИЛИ_НА_ОБЩИЙ_СПИСОК                |
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
//| ОПРЕДЕЛИМ_РАЗДЕЛИТЕЛЬ_ДЛЯ_ФОРМАТА_ДАТЫ                           |
//+------------------------------------------------------------------+
void SetSeparateForFormatDate()
  {
   switch(format_date)
     {
      case SEP_POINT1 : case SEP_POINT2 : sep="."; break; // Разделитель точка
      case SEP_SLASH1 : case SEP_SLASH2 : sep="/"; break; // Разделитель косая черта (слэш (slash))
      case SEP_1c1 : sep="."; break; // Разделитель точка
      case SEP_1c2 : sep=""; break; // нет разделелителя
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ПОЛУЧИМ_ДАННЫЕ_СИМВОЛОВ                                          |
//+------------------------------------------------------------------+
int GetDataCurrentSymbol(int s)
  {
   Print("------\n№"+IS(s+1)+" >>>"); // Выведем в журнал номер символа
//---
// Проверяет и скачивает нужное количество запрошенных данных
   int res=CheckLoadHistory(s,_Period);
//---
   InfoTable(s); ChartRedraw(); // Обновим данные в информационной таблице
//---
   switch(res)
     {
      case -1 : Print("Неизвестный символ "+symbols[s]+" (code: -1)!");                         return(0);
      case -2 :
         Print("Запрошенных баров больше, чем можно отобразить на графике (code: -2)!...\n"
               "...Будет использовано для записи столько данных сколько доступно.");            break;
      //---
      case -3 : Print("Выполнение было прервано пользователем (code: -3)!");                    return(2);
      case -4 : Print("Загрузка окончилась неудачей (code: -4)!");                              return(0);
      case  0 : Print("Все данные символа загружены (code: 0).");                               break;
      case  1 : Print("Уже имеющихся данных в таймсерии достаточно (code: 1).");                break;
      case  2 : Print("Таймсерия построена из имеющихся данных терминала (code: 2).");          break;
      //---
      default : Print("Результат выполнения не определен!");
     }
//---
// Скопируем данные в массив
   if(CopyRates(symbols[s],_Period,check_start_date,end_date,rates)<=0)
     { Print("Ошибка копирования данных символа "+symbols[s]+" - ",ErrorDesc(Error())+""); return(0); }
   else
     {
      copied_bars=ArraySize(rates); // Получим размер массива
      //---
      Print("Symbol: ",symbols[s],"; Timeframe: ",gStrTF(_Period),"; Copied bars: ",copied_bars);
     }
//---
   return(1); // Вернём 1, если прошло успешно
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ПРОВЕРЯЕТ_И_СКАЧИВАЕТ_НУЖНОЕ_КОЛИЧЕСТВО_ЗАПРОШЕННЫХ_ДАННЫХ       |
//+------------------------------------------------------------------+
int CheckLoadHistory(int s,ENUM_TIMEFRAMES period)
  {
   datetime times[100]; // Массив для постепенной загрузки данных
//---
// Проверяет и добавляет символ в окно Обзор Рынка, если его там нет
   if(!SymbolInfoInteger(symbols[s],SYMBOL_SELECT))
     {
      if(Error()==ERR_MARKET_UNKNOWN_SYMBOL)
        { return(-1); } // Возвращает -1, если ошибка "Неизвестный символ"
      //---
      SymbolSelect(symbols[s],true); // Добавим символ в окно Обзор Рынка
     }
//---
// Проверка на уже имеющееся количество истории
   SeriesInfoInteger(symbols[s],period,SERIES_FIRSTDATE,first_date); // Запрос первой даты истории
//---
   if(first_date>0 && first_date<=start_date) { check_start_date=start_date; return(1); } // Вернём 1, если истории достаточно для работы
//---
// Если дошли до этого места, то значит истории недостаточно
// Узнаем начальную дату, для которой доступны минутные данные
   if(SeriesInfoInteger(symbols[s],PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,first_termnl_date))
     {
      // Если данные имеются
      if(first_termnl_date>0)
        {
         // Принудительное формирование таймсерии путём копирования времени первого бара указанного таймфрейма
         CopyTime(symbols[s],period,first_termnl_date+PeriodSeconds(period),1,times);
         //---
         // Вторая проверка. Запрос первой даты истории.
         if(SeriesInfoInteger(symbols[s],period,SERIES_FIRSTDATE,first_date))
           {
            // Если таймсерия была построена из имеющихся данных терминала и теперь их количества достаточно...
            if(first_date>0 && first_date<=start_date)
              { check_start_date=start_date; return(2); } // ...вернём 2
           }
        }
     }
//________________________________________________________________
// Если дошли до этого места, то данных меньше, чем было запрошено
// Будет произведена попытка загрузить данные с сервера
//---
   int cnt_try=0,tl_try=2;
//---
// Запросим самую первую дату данных с сервера
   while(!SeriesInfoInteger(symbols[s],PERIOD_M1,SERIES_SERVER_FIRSTDATE,first_server_date))
     {
      if(IsStopped()) { return(-3); } // Выполнение прервано пользователем
      //---
      cnt_try++; // Увеличим счётчик
      //---
      Print(nmf,"Подождите пожалуйста. Программа пытается загрузить историю символа ["+symbols[s]+"] (попытка: "+IS(cnt_try)+"/"+IS(tl_try)+")...");
      //---
      // Всего будет две попытки
      if(cnt_try==2) { break; } Sleep(1000);
     }
//---
   Print("Самая первая дата данных на сервере: ",first_server_date);
//---
// Если на сервере есть больше данных, чем было запрошено, то...
   if(first_server_date>start_date)
     { check_start_date=first_server_date; } // ...загрузим их (запомним время первого бара)
//---
// Если уже имеющихся данных в базе данных терминала больше, чем на сервере
   if(first_date>0 && first_date<first_server_date) // Выведем сообщение об этом
     {
      Print("Внимание! В базе данных терминала больше данных, чем на сервере.\n",
            "Самая первая дата данных на сервере: ",first_server_date,".\n",
            "Самая первая дата данных в базе данных терминала: ",first_termnl_date);
     }
//---
// Порционная загрузка по 100 баров до указанной начальной даты
   cnt_try=0; // Обнулим счётчик попыток
//---
// Цикл будет выполняться до тех пор пока не остановит пользователь...
   while(!IsStopped()) // ...либо счётчик не будет переполнен в теле цикла
     {
      // Проверяет пока история не будет синхронизирована
      while(!SeriesInfoInteger(symbols[s],period,SERIES_SYNCHRONIZED))
        {
         if(IsStopped()) { return(-3); } // Выполнение прервано пользователем
         //---
         bool flg_msg=false;
         if(!flg_msg) { Print(nmf,"Подождите пожалуйста. Процесс синхронизации истории..."); flg_msg=true; }
         Sleep(1000);
        }
      //---
      // Получим количество баров по указанному таймфрейму
      bars=Bars(symbols[s],period);
      //---
      if(bars>0) // Если есть результат, то...
        {
         // ...если баров указанного периода больше, ...
         // чем установлено в опции терминала "Макс. количество баров в окне"...
         if(bars>=max_bars)
           {
            // Скорректируем дату, с которой будем копировать данные
            datetime time_fb[];
            //---
            // Получим первую доступную дату и запоним её
            CopyTime(symbols[s],period,bars,1,time_fb);
            check_start_date=time_fb[0];
            //---
            return(-2); // ... вернём -2
           }
         //---
         // Запросим самую первую дату по указанному периоду
         if(SeriesInfoInteger(symbols[s],period,SERIES_FIRSTDATE,first_date))
           {
            // Если дата меньше либо равна указанной начальной дате в настройках скрипта...
            if(first_date>0 && first_date<=check_start_date) { return(0); } // ...вернём 0
           }
        }
      //---
      // Если дошли до этого места, то значит, что данных пока недостаточное количество
      // Запросим новую порцию истории в 100 баров у торгового сервера от последнего доступного бара под номером bars
      int copied=CopyTime(symbols[s],period,bars,100,times);
      //---
      if(copied>0) // Если запрос удачен
        {
         // Проверим данные
         // Если время первого доступного бара теперь меньше либо равен указанного начального...
         if(times[0]<=check_start_date) { return(0); } // ...вернём 0
         //---
         // Если количество (баров+скопированное количество) больше либо равно...
         // ...количеству указанному в опции терминала "Макс. количество баров в окне"
         if(bars+copied>=max_bars)
           {
            // Скорректируем дату, с которой будем копировать данные
            datetime time_fb[];
            CopyTime(symbols[s],period,max_bars,1,time_fb);
            check_start_date=time_fb[0];
            //---
            return(-2); // ...вернём -2
           }
         //---
         cnt_try=0;
        }
      else // Если запрос закончился неудачей, то...
        {
         // ...увеличим счётчик неудачных попыток
         cnt_try++;
         //---
         // Если уже было 2 попытки, то...
         if(cnt_try>=1) { return(-4); } // ...вернём -4
         //---
         Print(nmf,"Подождите пожалуйста. Идёт процесс загрузки данных..."); Sleep(1000);
        }
     }
//---
// Выполнение было прервано пользователем
   return(-3);
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ЗАПИШЕМ_ДАННЫЕ_В_ФАЙЛ                                            |
//+------------------------------------------------------------------+
void WriteDataToFile(int s)
  {
// Количество знаков в цене символа после запятой
   int dgt=(int)SymbolInfoInteger(symbols[s],SYMBOL_DIGITS);
//---
   string nm_fl=path+symbols[s]+"_"+gStrTF(_Period)+".csv"; // Имя файла
//---
// Получим хэндл файла для записи
   hFl=FileOpen(nm_fl,FILE_WRITE|FILE_CSV|FILE_ANSI,',');
//---
   if(hFl>0) // Если хэндл получен
     {
      // Запишем заголовки
      if(format_headers==NSDT_5)
        { FileWrite(hFl,"\"Date\" ""\"Time\" ""\"Open\" ""\"High\" ""\"Low\" ""\"Close\" ""\"Volume\""); }
      //---
      if(format_headers==NSDT_6)
        { FileWrite(hFl,"Date","Open","High","Low","Close","Volume"); }
      //---
      if(format_headers==CSV_1C)
        { FileWrite(hFl,"Date","Open","High","Low","Close","Volume","Spread"); }
      //---
      // Запишем данные
      for(int i=0; i<=copied_bars-1; i++)
        {
         if(IsStopped()) // Если выполнение программы прервано пользователем
           {
            DelAllScriptObjects(); // Удаляем объекты с графика, которые создал скрипт
            //---
            Print("------\nПользователь удалил скрипт!"); break;
           }
         //---
         sdt=TSdm(rates[i].time); // Время открытия бара
         //---
         // Разъединим дату на год, месяц, число, время
         yyyy=StringSubstr(sdt,0,4);
         mm=StringSubstr(sdt,5,2);
         dd=StringSubstr(sdt,8,2);
         tm=StringSubstr(sdt,11);
         if(format_date==SEP_1c2) { tm=StringSubstr(sdt,11,2)+StringSubstr(sdt,14,2); }
         //---
         string sep_dt_tm=""; // Разделитель столбцов Date и Time
         //---
         // Соединим данные с разделителем и в нужном порядке
         if(format_date==SEP_POINT1 || format_date==SEP_SLASH1 || format_date==SEP_1c1) { sep_dt_tm=" "; }
         if(format_date==SEP_POINT2 || format_date==SEP_SLASH2) { sep_dt_tm=","; }
         if(format_date==SEP_1c2) { sep_dt_tm=""; }
         //---
         // Соединяем всё в одну строку
         if(format_date==SEP_1c1 || format_date==SEP_1c2) {StringConcatenate(sdt,yyyy,sep,mm,sep,dd,sep_dt_tm,tm);}
         else {StringConcatenate(sdt,dd,sep,mm,sep,yyyy,sep_dt_tm,tm);};
         //---
         FileWrite(hFl,
                   sdt,// Дата-время
                   DS_dgt(rates[i].open,dgt),  // Цена открытия
                   DS_dgt(rates[i].high,dgt),  // Цена максимума
                   DS_dgt(rates[i].low,dgt),   // Цена минимума
                   DS_dgt(rates[i].close,dgt), // Цена закрытия
                   IS((int)rates[i].tick_volume),// Цена тикового объёма
                   IS((int)rates[i].spread)); //Спред в пунктах
         //---
         if(show_progress)
           {
            // Обновим значение прогресса записи для текущего символа
            pgs_pcnt=((int)(i+1)/copied_bars)*100;
            //---
            // Обновим данные в таблице
            if(pgs_pcnt!=pgs_pcnt_prev)
              {
               InfoTable(s);
               ChartRedraw();
               pgs_pcnt_prev=pgs_pcnt;
              }
           }
        }
      //---
      FileClose(hFl); // Закроем файл
     }
   else { Print("Ошибка при создании/открытии файла!"); }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ПРОВЕРЯЕТ_ДИРЕКТОРИЮ_И_СОЗДАЁТ_НУЖНЫЕ_ПАПКИ_ДЛЯ_ДАННЫХ           |
//+------------------------------------------------------------------+
string CheckCreateGetPath(int s)
  {
   int i=1;
   long search=-1;
   string ffname="",lpath="";
   string file="*.csv",folder="*";
   string
   root="DATA_OHLC\\",// Корневая папка данных
   fSmb=symbols[s]+"\\",// Имя символа
   fTF=gStrTF(_Period)+"\\"; // Таймфрейм символа
//---
   bool flgROOT=false,flgSYMBOL=false;
//---
//+------------------------------------------------------------------+
//| ИЩЕМ_КОРНЕВУЮ_ПАПКУ_DATA_OHLC                                    |
//+------------------------------------------------------------------+
   lpath=folder;
   search=FileFindFirst(lpath,ffname); // Установим хэндл поиска в папке - Metatrader 5\MQL5\Files
//---
   Print("Директория: ",TRM_DP+"\\MQL5\\Files\\");
//---
// Если первая папка корневая, ставим флаг
   if(ffname==root)
     { flgROOT=true; Print("Корневая папка "+root+" существует"); }
//---
   if(search!=INVALID_HANDLE) // Если хэндл поиска получен
     {
      if(!flgROOT) // Если первая папка была некорневой
        {
         // Перебираем все файлы с целью поиска корневой папки
         while(FileFindNext(search,ffname))
           {
            if(IsStopped()) // Выполнение прервано пользователем
              {
               // Удаляем объекты с графика, которые создал скрипт
               DelAllScriptObjects();
               //---
               Print("------\nПользователь удалил скрипт!"); return("");
              }
            //---
            if(ffname==root) // Если находим, то ставим флаг
              { flgROOT=true; Print("Корневая папка "+root+" существует"); break; }
           }
        }
      //---
      FileFindClose(search); search=-1; // Закроем хэндл поиска корневой папки
     }
   else { Print("Ошибка при получении хэндла поиска либо директория "+TRM_DP+" пуста: ",ErrorDesc(Error())); }
//---
//+------------------------------------------------------------------+
//| ИЩЕМ_ПАПКУ_СИМВОЛА                                               |
//+------------------------------------------------------------------+
   lpath=root+folder;
//---
// Установим хэндл поиска в корневой папке ..\Files\DATA OHLC\
   search=FileFindFirst(lpath,ffname);
//---
// Если первая папка текущего символа, ставим флаг
   if(ffname==fSmb) { flgSYMBOL=true; Print("Папка символа "+fSmb+" существует"); }
//---
   if(search!=INVALID_HANDLE) // Если хэндл поиска получен
     {
      if(!flgSYMBOL) // Если первая папка была не текущего символа
        {
         // Перебираем все файлы в корневой папке с целью поиска папки символа
         while(FileFindNext(search,ffname))
           {
            if(IsStopped()) // Выполнение прервано пользователем
              {
               // Удаляем объекты с графика, которые создал скрипт
               DelAllScriptObjects();
               //---
               Print("------\nПользователь удалил скрипт!"); return("");
              }
            //---
            if(ffname==fSmb) // Если находим, то ставим флаг
              { flgSYMBOL=true; Print("Папка символа "+fSmb+" существует"); break; }
           }
        }
      //---
      FileFindClose(search); search=-1; // Закроем хэндл поиска папки символа
     }
   else { Print("Ошибка при получении хэндла поиска либо директория "+path+" пуста"); }
//---
//+------------------------------------------------------------------+
//| ПО_РЕЗУЛЬТАТАМ_ПРОВЕРКИ_СОЗДАДИМ_НУЖНЫЕ_КАТАЛОГИ                 |
//+------------------------------------------------------------------+
   if(!flgROOT) // Если нет корневой папки DATA_OHLC...
     {
      if(FolderCreate("DATA_OHLC")) // ...создадим её
        { Print("Создана корневая папка ..\DATA_OHLC\\"); }
      else
        { Print("Ошибка при создании корневой папки DATA_OHLC: ",ErrorDesc(Error())); return(""); }
     }
//---
   if(!flgSYMBOL) // Если нет папки символа, значения которого нужно получить...
     {
      if(FolderCreate(root+symbols[s])) // ...создадим её
        {
         Print("Создана папка символа ..\DATA_OHLC\\"+fSmb+"");
         //---
         return(root+symbols[s]+"\\"); // Вернём путь, в котором будет создан файл для записи
        }
      else
        { Print("Ошибка при создании папки символа ..\DATA_OHLC\\"+fSmb+"\: ",ErrorDesc(Error())); return(""); }
     }
//---
   if(flgROOT && flgSYMBOL)
     {
      return(root+symbols[s]+"\\"); // Вернём путь, в котором будет создан файл для записи
     }
//---
   return("");
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ИНФОРМАЦИОННАЯ_ПАНЕЛЬ                                            |
//|------------------------------------------------------------------+
void InfoTable(int s)
  {
   int fnt_sz=8;            // Размер шрифта
   string fnt="Calibri";    // Шрифт заголовков
   color clr=clrWhiteSmoke; // Цвет
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
//| СОЗДАНИЕ_ОБЪЕКТА_LABEL                                           |
//+------------------------------------------------------------------+
void Create_Label(long   chrt_id,   // id графика
                  string lable_nm,  // имя объекта
                  string rename,    // отображаемое имя
                  long   anchor,    // точка привязки
                  long   corner,    // угол привязки
                  string font_bsc,  // шрифт
                  int    font_size, // размер шрифта
                  color  font_clr,  // цвет шрифта
                  int    x_dist,    // координата по шкале X
                  int    y_dist,    // координата по шкале Y
                  long   zorder)    // приоритет
  {
   if(ObjectCreate(chrt_id,lable_nm,OBJ_LABEL,0,0,0)) // создание объекта
     {
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TEXT,rename);          // установка имени
      ObjectSetString(chrt_id,lable_nm,OBJPROP_FONT,font_bsc);        // установка шрифта
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_COLOR,font_clr);      // установка цвета шрифта
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ANCHOR,anchor);       // установка точки привязки
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_CORNER,corner);       // установка угола привязки
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_FONTSIZE,font_size);  // установка размера шрифта
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_XDISTANCE,x_dist);    // установка координаты X
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_YDISTANCE,y_dist);    // установка координаты Y
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_SELECTABLE,false);    // нельзя выделить объект, если FALSE
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ZORDER,zorder);       // Приоритет выше/ниже
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TOOLTIP,"\n");         // нет всплывающей подсказки, если "\n"
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| СОЗДАНИЕ_ОБЪЕКТА_EDIT                                            |
//+------------------------------------------------------------------+
void Create_Edit(long   chrt_id,       // id графика
                 int    nmb_win,       // номер окна (подокна)
                 string lable_nm,      // имя объекта
                 string text,          // отображаемый текст
                 long   corner,        // угол привязки
                 string font_bsc,      // шрифт
                 int    font_size,     // размер шрифта
                 color  font_clr,      // цвет шрифта
                 color  font_clr_brd,  // цвет шрифта
                 int    xsize,         // ширина
                 int    ysize,         // высота
                 int    x_dist,        // координата по шкале X
                 int    y_dist,        // координата по шкале Y
                 long   zorder,        // приоритет
                 color  clr)           // цвет фона
  {
   if(ObjectCreate(chrt_id,lable_nm,OBJ_EDIT,nmb_win,0,0)) // создание объекта
     {
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TEXT,text);                     // установка имени
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_CORNER,corner);                // установка угла привязки
      ObjectSetString(chrt_id,lable_nm,OBJPROP_FONT,font_bsc);                 // установка шрифта
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ALIGN,ALIGN_CENTER);           // выравнивание по центру
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_FONTSIZE,font_size);           // установка размера шрифта
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_COLOR,font_clr);               // цвет шрифта
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_BORDER_COLOR,font_clr_brd);    // цвет фона
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_BGCOLOR,clr);                  // цвет фона
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_XSIZE,xsize);                  // ширина
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_YSIZE,ysize);                  // высота
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_XDISTANCE,x_dist);             // установка координаты X
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_YDISTANCE,y_dist);             // установка координаты Y
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_SELECTABLE,false);             // нельзя выделить объект, если FALSE
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ZORDER,zorder);                // Приоритет выше/ниже
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_READONLY,true);                // Только для чтения
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TOOLTIP,"\n");                  // нет всплывающей подсказки, если "\n"
     }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| УДАЛЯЕТ_ВСЕ_ГРАФИЧЕСКИЕ_ОБЪЕКТЫ_КОТОРЫЕ_СОЗДАЛ_СКРИПТ            |
//+------------------------------------------------------------------+
void DelAllScriptObjects()
  {
// Получим размер массива имён графических объектов
   int sz_arr1=ArraySize(arr_nmobj);
//---
// Удалим все объекты
   for(int i=0; i<sz_arr1; i++)
     { DelObjbyName(arr_nmobj[i]);  }
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| УДАЛЯЕТ_ОБЪЕКТЫ_ПО_ИМЕНИ                                         |
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
      if(!res) { Print("Ошибка при удалении объекта: - "+ErrorDesc(Error())+""); return(false); }
     }
//---
   return(res);
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| КОНВЕРТАЦИЯ_ИЗ_DATETIME_В_STRING_В_ФОРМАТЕ_TIME_DATE             |
//+------------------------------------------------------------------+
string TSd(datetime aValue)
  {
   return(TimeToString(aValue,TIME_DATE));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| КОНВЕРТАЦИЯ_ИЗ_DATETIME_В_STRING_                                |
//| В_ФОРМАТЕ_TIME_DATE|TIME_MINUTES                                 |
//+------------------------------------------------------------------+
string TSdm(datetime aValue)
  {
   return(TimeToString(aValue,TIME_DATE|TIME_MINUTES));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| КОНВЕРТАЦИЯ_ИЗ_INTEGER_В_STRING                                  |
//+------------------------------------------------------------------+
string IS(int aValue)
  {
   return(IntegerToString(aValue));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| КОНВЕРТАЦИЯ_ИЗ_DOUBLE_В_STRING                                   |
//+------------------------------------------------------------------+
string DS(double aValue,int amount)
  {
   return(DoubleToString(aValue,amount));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| КОНВЕРТАЦИЯ_ИЗ_DOUBLE_В_STRING_С_DIGITS_ЗНАКАМИ                  |
//+------------------------------------------------------------------+
string DS_dgt(double aValue,int digit)
  {
   return(DoubleToString(aValue,digit));
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ВОЗВРАЩАЕТ_СТРОКУ_TIMEFRAME                                      |
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
      default : str="Неизвестный таймфрейм!";
     }
//---
   return(str);
  }
//____________________________________________________________________
//+------------------------------------------------------------------+
//| ПОЛУЧАЕТ_ПОСЛЕДНЮЮ_ЗАФИКСИРОВАННУЮ_ОШИБКУ                        |
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
      //--- Коды возврата торгового сервера
      case 10004: error_string=""+IS(Error())+": Реквота";                                                         break;
      case 10006: error_string=""+IS(Error())+": Запрос отвергнут";                                                break;
      case 10007: error_string=""+IS(Error())+": Запрос отменён трейдером";                                        break;
      case 10008: error_string=""+IS(Error())+": Ордер размещён";                                                  break;
      case 10009: error_string=""+IS(Error())+": Заявка выполнена";                                                break;
      case 10010: error_string=""+IS(Error())+": Заявка выполнена частично";                                       break;
      case 10011: error_string=""+IS(Error())+": Ошибка обработки запроса";                                        break;
      case 10012: error_string=""+IS(Error())+": Запрос отменён по истечению времени";                             break;
      case 10013: error_string=""+IS(Error())+": Неправильный запрос";                                             break;
      case 10014: error_string=""+IS(Error())+": Неправильный объём в запросе";                                    break;
      case 10015: error_string=""+IS(Error())+": Неправильная цена в запросе";                                     break;
      case 10016: error_string=""+IS(Error())+": Неправильные стопы в запросе";                                    break;
      case 10017: error_string=""+IS(Error())+": Торговля запрещена";                                              break;
      case 10018: error_string=""+IS(Error())+": Рынок закрыт";                                                    break;
      case 10019: error_string=""+IS(Error())+": Нет достаточных денежных средств";                                break;
      case 10020: error_string=""+IS(Error())+": Цены изменились";                                                 break;
      case 10021: error_string=""+IS(Error())+": Отсутствуют котировки для обработки запроса";                     break;
      case 10022: error_string=""+IS(Error())+": Неверная дата истечения ордера в запросе";                        break;
      case 10023: error_string=""+IS(Error())+": Состояние ордера изменилось";                                     break;
      case 10024: error_string=""+IS(Error())+": Слишком частые запросы";                                          break;
      case 10025: error_string=""+IS(Error())+": В запросе нет изменений";                                         break;
      case 10026: error_string=""+IS(Error())+": Автотрейдинг запрещён трейдером";                                 break;
      case 10027: error_string=""+IS(Error())+": Автотрейдинг запрещён клиентским терминалом";                     break;
      case 10028: error_string=""+IS(Error())+": Запрос заблокирован для обработки";                               break;
      case 10029: error_string=""+IS(Error())+": Ордер или позиция заморожены";                                    break;
      case 10030: error_string=""+IS(Error())+": Указан неподдерживаемый тип исполнения ордера по остатку";        break;
      case 10031: error_string=""+IS(Error())+": Нет соединения с торговым сервером";                              break;
      case 10032: error_string=""+IS(Error())+": Операция разрешена только для реальных счетов";                   break;
      case 10033: error_string=""+IS(Error())+": Достигнут лимит на количество отложенных ордеров";                break;
      case 10034: error_string=""+IS(Error())+": Достигнут лимит на объём ордеров и позиций для данного символа";  break;

      //--- Ошибки времени выполнения

      case 0:  // Операция выполнена успешно
      case 4001: error_string=""+IS(Error())+": Неожиданная внутренняя ошибка";                                                                                                   break;
      case 4002: error_string=""+IS(Error())+": Ошибочный параметр при внутреннем вызове функции клиентского терминала";                                                          break;
      case 4003: error_string=""+IS(Error())+": Ошибочный параметр при вызове системной функции";                                                                                 break;
      case 4004: error_string=""+IS(Error())+": Недостаточно памяти для выполнения системной функции";                                                                            break;
      case 4005: error_string=""+IS(Error())+": Структура содержит объекты строк и/или динамических массивов и/или структуры с такими объектами и/или классы";                    break;
      case 4006: error_string=""+IS(Error())+": Массив неподходящего типа, неподходящего размера или испорченный объект динамического массива";                                   break;
      case 4007: error_string=""+IS(Error())+": Недостаточно памяти для перераспределения массива либо попытка изменения размера статического массива";                           break;
      case 4008: error_string=""+IS(Error())+": Недостаточно памяти для перераспределения строки";                                                                                break;
      case 4009: error_string=""+IS(Error())+": Неинициализированная строка";                                                                                                     break;
      case 4010: error_string=""+IS(Error())+": Неправильное значение даты и/или времени";                                                                                        break;
      case 4011: error_string=""+IS(Error())+": Запрашиваемый размер массива превышает 2 гигабайта";                                                                              break;
      case 4012: error_string=""+IS(Error())+": Ошибочный указатель";                                                                                                             break;
      case 4013: error_string=""+IS(Error())+": Ошибочный тип указателя";                                                                                                         break;
      case 4014: error_string=""+IS(Error())+": Системная функция не разрешена для вызова";                                                                                       break;
      //-- Графики
      case 4101: error_string=""+IS(Error())+": Ошибочный идентификатор графика";                                                                                                 break;
      case 4102: error_string=""+IS(Error())+": График не отвечает";                                                                                                              break;
      case 4103: error_string=""+IS(Error())+": График не найден";                                                                                                                break;
      case 4104: error_string=""+IS(Error())+": У графика нет эксперта, который мог бы обработать событие";                                                                       break;
      case 4105: error_string=""+IS(Error())+": Ошибка открытия графика";                                                                                                         break;
      case 4106: error_string=""+IS(Error())+": Ошибка при изменении для графика символа и периода";                                                                              break;
      case 4107: error_string=""+IS(Error())+": Ошибочный параметр для таймера";                                                                                                  break;
      case 4108: error_string=""+IS(Error())+": Ошибка при создании таймера";                                                                                                     break;
      case 4109: error_string=""+IS(Error())+": Ошибочный идентификатор свойства графика";                                                                                        break;
      case 4110: error_string=""+IS(Error())+": Ошибка при создании скриншота";                                                                                                   break;
      case 4111: error_string=""+IS(Error())+": Ошибка навигации по графику";                                                                                                     break;
      case 4112: error_string=""+IS(Error())+": Ошибка при применении шаблона";                                                                                                   break;
      case 4113: error_string=""+IS(Error())+": Подокно, содержащее указанный индикатор, не найдено";                                                                             break;
      case 4114: error_string=""+IS(Error())+": Ошибка при добавлении индикатора на график";                                                                                      break;
      case 4115: error_string=""+IS(Error())+": Ошибка при удалении индикатора с графика";                                                                                        break;
      case 4116: error_string=""+IS(Error())+": Индикатор не найден на указанном графике";                                                                                        break;
      //-- Графические объекты
      case 4201: error_string=""+IS(Error())+": Ошибка при работе с графическим объектом";                                                                                        break;
      case 4202: error_string=""+IS(Error())+": Графический объект не найден";                                                                                                    break;
      case 4203: error_string=""+IS(Error())+": Ошибочный идентификатор свойства графического объекта";                                                                           break;
      case 4204: error_string=""+IS(Error())+": Невозможно получить дату, соответствующую значению";                                                                              break;
      case 4205: error_string=""+IS(Error())+": Невозможно получить значение, соответствующее дате";                                                                              break;
      //-- MarketInfo
      case 4301: error_string=""+IS(Error())+": Неизвестный символ";                                                                                                              break;
      case 4302: error_string=""+IS(Error())+": Символ не выбран в MarketWatch";                                                                                                  break;
      case 4303: error_string=""+IS(Error())+": Ошибочный идентификатор свойства символа";                                                                                        break;
      case 4304: error_string=""+IS(Error())+": Время последнего тика неизвестно (тиков не было)";                                                                                break;
      //-- Доступ к истории
      case 4401: error_string=""+IS(Error())+": Запрашиваемая история не найдена!";                                                                                               break;
      case 4402: error_string=""+IS(Error())+": Ошибочный идентификатор свойства истории";                                                                                        break;
      //-- Global_Variables
      case 4501: error_string=""+IS(Error())+": Глобальная переменная клиентского терминала не найдена";                                                                          break;
      case 4502: error_string=""+IS(Error())+": Глобальная переменная клиентского терминала с таким именем уже существует";                                                       break;
      case 4510: error_string=""+IS(Error())+": Не удалось отправить письмо";                                                                                                     break;
      case 4511: error_string=""+IS(Error())+": Не удалось воспроизвести звук";                                                                                                   break;
      case 4512: error_string=""+IS(Error())+": Ошибочный идентификатор свойства программы";                                                                                      break;
      case 4513: error_string=""+IS(Error())+": Ошибочный идентификатор свойства терминала";                                                                                      break;
      case 4514: error_string=""+IS(Error())+": Не удалось отправить файл по ftp";                                                                                                break;
      //-- Буфера пользовательских индикаторов
      case 4601: error_string=""+IS(Error())+": Недостаточно памяти для распределения индикаторных буферов";                                                                      break;
      case 4602: error_string=""+IS(Error())+": Ошибочный индекс своего индикаторного буфера";                                                                                    break;
      //-- Свойства пользовательских индикаторов
      case 4603: error_string=""+IS(Error())+": Ошибочный идентификатор свойства пользовательского индикатора";                                                                   break;
      //-- Account
      case 4701: error_string=""+IS(Error())+": Ошибочный идентификатор свойства счета";                                                                                          break;
      case 4751: error_string=""+IS(Error())+": Ошибочный идентификатор свойства торговли";                                                                                       break;
      case 4752: error_string=""+IS(Error())+": Торговля для эксперта запрещена";                                                                                                 break;
      case 4753: error_string=""+IS(Error())+": Позиция не найдена";                                                                                                              break;
      case 4754: error_string=""+IS(Error())+": Ордер не найден";                                                                                                                 break;
      case 4755: error_string=""+IS(Error())+": Сделка не найдена";                                                                                                               break;
      case 4756: error_string=""+IS(Error())+": Не удалось отправить торговый запрос";                                                                                            break;
      //-- Индикаторы
      case 4801: error_string=""+IS(Error())+": Неизвестный символ";                                                                                                              break;
      case 4802: error_string=""+IS(Error())+": Индикатор не может быть создан";                                                                                                  break;
      case 4803: error_string=""+IS(Error())+": Недостаточно памяти для добавления индикатора";                                                                                   break;
      case 4804: error_string=""+IS(Error())+": Индикатор не может быть применен к другому индикатору";                                                                           break;
      case 4805: error_string=""+IS(Error())+": Ошибка при добавлении индикатора";                                                                                                break;
      case 4806: error_string=""+IS(Error())+": Запрошенные данные не найдены";                                                                                                   break;
      case 4807: error_string=""+IS(Error())+": Ошибочный хэндл индикатора";                                                                                                      break;
      case 4808: error_string=""+IS(Error())+": Неправильное количество параметров при создании индикатора";                                                                      break;
      case 4809: error_string=""+IS(Error())+": Отсутствуют параметры при создании индикатора";                                                                                   break;
      case 4810: error_string=""+IS(Error())+": Первым параметром в массиве должно быть имя пользовательского индикатора";                                                        break;
      case 4811: error_string=""+IS(Error())+": Неправильный тип параметра в массиве при создании индикатора";                                                                    break;
      case 4812: error_string=""+IS(Error())+": Ошибочный индекс запрашиваемого индикаторного буфера";                                                                            break;
      //-- Стакан цен
      case 4901: error_string=""+IS(Error())+": Стакан цен не может быть добавлен";                                                                                               break;
      case 4902: error_string=""+IS(Error())+": Стакан цен не может быть удален";                                                                                                 break;
      case 4903: error_string=""+IS(Error())+": Данные стакана цен не могут быть получены";                                                                                       break;
      case 4904: error_string=""+IS(Error())+": Ошибка при подписке на получение новых данных стакана цен";                                                                       break;
      //-- Файловые операции
      case 5001: error_string=""+IS(Error())+": Не может быть открыто одновременно более 64 файлов";                                                                              break;
      case 5002: error_string=""+IS(Error())+": Недопустимое имя файла";                                                                                                          break;
      case 5003: error_string=""+IS(Error())+": Слишком длинное имя файла";                                                                                                       break;
      case 5004: error_string=""+IS(Error())+": Ошибка открытия файла";                                                                                                           break;
      case 5005: error_string=""+IS(Error())+": Недостаточно памяти для кеша чтения";                                                                                             break;
      case 5006: error_string=""+IS(Error())+": Ошибка удаления файла";                                                                                                           break;
      case 5007: error_string=""+IS(Error())+": Файл с таким хэндлом уже был закрыт, либо не открывался вообще";                                                                  break;
      case 5008: error_string=""+IS(Error())+": Ошибочный хэндл файла";                                                                                                           break;
      case 5009: error_string=""+IS(Error())+": Файл должен быть открыт для записи";                                                                                              break;
      case 5010: error_string=""+IS(Error())+": Файл должен быть открыт для чтения";                                                                                              break;
      case 5011: error_string=""+IS(Error())+": Файл должен быть открыт как бинарный";                                                                                            break;
      case 5012: error_string=""+IS(Error())+": Файл должен быть открыт как текстовый";                                                                                           break;
      case 5013: error_string=""+IS(Error())+": Файл должен быть открыт как текстовый или CSV";                                                                                   break;
      case 5014: error_string=""+IS(Error())+": Файл должен быть открыт как CSV";                                                                                                 break;
      case 5015: error_string=""+IS(Error())+": Ошибка чтения файла";                                                                                                             break;
      case 5016: error_string=""+IS(Error())+": Должен быть указан размер строки, так как файл открыт как бинарный";                                                              break;
      case 5017: error_string=""+IS(Error())+": Для строковых массивов должен быть текстовый файл, для остальных – бинарный";                                                     break;
      case 5018: error_string=""+IS(Error())+": Это не файл, а директория";                                                                                                       break;
      case 5019: error_string=""+IS(Error())+": Файл не существует";                                                                                                              break;
      case 5020: error_string=""+IS(Error())+": Файл не может быть переписан";                                                                                                    break;
      case 5021: error_string=""+IS(Error())+": Ошибочное имя директории";                                                                                                        break;
      case 5022: error_string=""+IS(Error())+": Директория не существует";                                                                                                        break;
      case 5023: error_string=""+IS(Error())+": Это файл, а не директория";                                                                                                       break;
      case 5024: error_string=""+IS(Error())+": Директория не может быть удалена";                                                                                                break;
      case 5025: error_string=""+IS(Error())+": Не удалось очистить директорию (возможно, один или несколько файлов заблокированы и операция удаления не удалась)";               break;
      //-- Преобразование строк
      case 5030: error_string=""+IS(Error())+": В строке нет даты";                                                                                                               break;
      case 5031: error_string=""+IS(Error())+": В строке ошибочная дата";                                                                                                         break;
      case 5032: error_string=""+IS(Error())+": В строке ошибочное время";                                                                                                        break;
      case 5033: error_string=""+IS(Error())+": Ошибка преобразования строки в дату";                                                                                             break;
      case 5034: error_string=""+IS(Error())+": Недостаточно памяти для строки";                                                                                                  break;
      case 5035: error_string=""+IS(Error())+": Длина строки меньше, чем ожидалось";                                                                                              break;
      case 5036: error_string=""+IS(Error())+": Слишком большое число, больше, чем ULONG_MAX";                                                                                    break;
      case 5037: error_string=""+IS(Error())+": Ошибочная форматная строка";                                                                                                      break;
      case 5038: error_string=""+IS(Error())+": Форматных спецификаторов больше, чем параметров";                                                                                 break;
      case 5039: error_string=""+IS(Error())+": Параметров больше, чем форматных спецификаторов";                                                                                 break;
      case 5040: error_string=""+IS(Error())+": Испорченный параметр типа string";                                                                                                break;
      case 5041: error_string=""+IS(Error())+": Позиция за пределами строки";                                                                                                     break;
      case 5042: error_string=""+IS(Error())+": К концу строки добавлен 0, бесполезная операция";                                                                                 break;
      case 5043: error_string=""+IS(Error())+": Неизвестный тип данных при конвертации в строку";                                                                                 break;
      case 5044: error_string=""+IS(Error())+": Испорченный объект строки";                                                                                                       break;
      //-- Работа с массивами
      case 5050: error_string=""+IS(Error())+": Копирование несовместимых массивов. Строковый массив может быть скопирован только в строковый, а числовой массив – в числовой";   break;
      case 5051: error_string=""+IS(Error())+": Приемный массив объявлен как AS_SERIES, и он недостаточного размера";                                                             break;
      case 5052: error_string=""+IS(Error())+": Слишком маленький массив, стартовая позиция за пределами массива";                                                                break;
      case 5053: error_string=""+IS(Error())+": Массив нулевой длины";                                                                                                            break;
      case 5054: error_string=""+IS(Error())+": Должен быть числовой массив";                                                                                                     break;
      case 5055: error_string=""+IS(Error())+": Должен быть одномерный массив";                                                                                                   break;
      case 5056: error_string=""+IS(Error())+": Таймсерия не может быть использована";                                                                                            break;
      case 5057: error_string=""+IS(Error())+": Должен быть массив типа double";                                                                                                  break;
      case 5058: error_string=""+IS(Error())+": Должен быть массив типа float";                                                                                                   break;
      case 5059: error_string=""+IS(Error())+": Должен быть массив типа long";                                                                                                    break;
      case 5060: error_string=""+IS(Error())+": Должен быть массив типа int";                                                                                                     break;
      case 5061: error_string=""+IS(Error())+": Должен быть массив типа short";                                                                                                   break;
      case 5062: error_string=""+IS(Error())+": Должен быть массив типа char";                                                                                                    break;
      //-- Пользовательские ошибки

      default: error_string="Ошибка не определена!";
     }
//----
   return(error_string);
  }
//+------------------------------------------------------------------+
