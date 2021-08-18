%macro create_all_vac_data;
/* Создаем файл для хранения ответа от API */
filename response "&json_path\hh_resp.json";

/* Обращаемся к API и получаем ответ. В качестве примера используем запрос 
   вакансий с Head Hunter */
proc http 
	url = "https://api.hh.ru/vacancies/?text=&search_text%nrstr(&)per_page=50"
	method = 'GET' 
	out = response;
run;

/* Создаем файл для хранения пользовательской карты JSON*/
filename num_p "&json_path\num_pages.map";

libname hh_p_num JSON fileref=response map=num_p;

/* поместим число страниц в макро переменную */
proc sql noprint;
	select pages-1
	into :num_pages
	from  HH_P_NUM.NUM_PAGES;
quit;

/* Уберем лишние начальные пробелы */
%let num_pages = %cmpres(&num_pages);

filename hh_vmap "&json_path\hh_vac.map";

%do i=0 %to %eval(&num_pages);
	proc http 
		url = "https://api.hh.ru/vacancies/?text=&search_text%nrstr(&)per_page=50%nrstr(&)page=&i"
		method = 'GET' 
		out = response;
	run;
	
	libname hh JSON fileref=response map=hh_vmap;
	
	data work.vacancy&i;
		set hh.vacancy;
	run;
%end;

/* Создадим библиотеку для хранения результата */
libname hh_res base "&json_path\result_data";

/* Получим список временных таблиц */
proc sql noprint;
	select memname
	into :tables separated by ' '
	from dictionary.members
	where memname contains 'VACANCY' and libname='WORK';
quit;
/* Поместим данные из временных таблиц в результат*/
data hh_res.vacancy;
	length vac_name $150 area_name $50 employer_name $100 salary_currency $4 schedule_name $40;
	set &tables;
run;

/* Удалим временные таблицы */
proc datasets library=work nolist;
delete &tables;
run;

%mend create_all_vac_data;


/* Запуск макроса */
%let json_path = C:\Users\rusage\Documents\Ask_the_expert\Импорт JSON из API в SAS;
%let search_text = IOT инженер;
%create_all_vac_data




