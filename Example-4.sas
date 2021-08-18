/* подготовка автокарты */
filename vac_resp temp;
proc http 
	url = "https://api.hh.ru/vacancies/43890190?host=hh.ru"
	method = 'GET' 
	out = vac_resp;
run;

filename vac_map "&json_path\vac_full.map";

libname vac JSON fileref=vac_resp map=vac_map automap=create;


/* просмотр результатов по собранной карте */
filename vac_map "&json_path\vac_short.map";

libname vac JSON fileref=vac_resp map=vac_map;


/* Усовершенствование макроса, полученного на предыдущем этапе */
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
	
	/* Добавлено по сравнению с Example-3 */
	/* Поместим число строк в полученной таблице в макро переменную */
	proc sql noprint;
		select count(*)
		into :row_num
		from work.vacancy&i;
	quit;
	/* создадим макро переменные для каждой вакансии */
	proc sql noprint ;
		select vac_url
		into :url_to_process1 - 
		from work.vacancy&i;
	quit;
	/* запускаем вложенный цикл для каждой вакансии*/
	%do j=1 %to %eval(%cmpres(&row_num));
		
		filename vac_resp temp;
		proc http 
			url = "&&url_to_process&j"
			method = 'GET' 
			out = vac_resp;
		run;
		filename vac_map "&json_path\vac_short.map";
		libname vac JSON fileref=vac_resp map=vac_map;
		
		/* Сгруппируем ключевые навыки в одну строку */
		proc sql noprint;
			select  name
			into :key_skills_name separated by ', ' 
			from  VAC.KEY_SKILLS;
		quit;
		
		/* Создадим таблицу для каждой вакансии*/
		data work.vac_info&j;
			set  VAC.VAC_INFO;
			key_skills = "&key_skills_name";
		run;
	%end;
	/* Получим список временных таблиц по каждой вакансии */
	proc sql noprint;
		select memname
		into :vac_tables separated by ' '
		from dictionary.members
		where memname contains 'VAC_INFO' and libname='WORK';
	quit;
	
	data work.vac_info_page;
		set &vac_tables;
	run;
	/* Объединим данные по вакансиям */
	proc sort data=work.vacancy&i out=work.vacancy&i;
		by vac_id;
	run;
	
	proc sort data=work.vac_info_page out=work.vac_info_page;
		by vac_id;
	run;
	
	data work.vacancy_full&i;
		length experience $50  key_skills $400;
		merge work.vacancy&i work.vac_info_page;
		by vac_id;
	run;
	
	/* Удалим временные таблицы */
	proc datasets library=work nolist;
		delete &vac_tables;
	run;
	
%end;

/* Создадим библиотеку для хранения результата */
libname hh_res base "&json_path\result_data";

/* Получим список временных таблиц */
proc sql noprint;
	select memname
	into :tables separated by ' '
	from dictionary.members
	where memname contains 'VACANCY_FULL' and libname='WORK';
quit;
/* Поместим данные из временных таблиц в результат*/
data hh_res.vacancy;
	length vac_name $150 area_name $50 employer_name $100 salary_currency $4 schedule_name $40;
	set &tables;
run;

/* Удалим временные таблицы */

proc sql noprint;
	select memname
	into :del_tables separated by ' '
	from dictionary.members
	where memname contains 'VAC' and libname='WORK';
quit;

proc datasets library=work nolist;
delete &del_tables;
run;

%mend create_all_vac_data;


/* Запуск макроса */
%let json_path = C:\Users\rusage\Documents\Ask_the_expert\Импорт JSON из API в SAS;
%let search_text = IOT инженер;
%create_all_vac_data




