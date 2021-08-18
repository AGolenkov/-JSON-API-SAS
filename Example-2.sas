/* SECTION-1. Запрос JSON с параметрами*/

%let json_path = C:\Users\rusage\Documents\Ask_the_expert\Импорт JSON из API в SAS;
/* Путь необходимо заменить на вашем устройстве */
%let search_text = продавец-кассир;

/* Создаем файл для хранения ответа от API */
filename response "&json_path\hh_resp.json";

/* Обращаемся к API и получаем ответ. В качестве примера используем запрос 
   вакансий продавца-кассира с Head Hunter */
proc http 
	url = "https://api.hh.ru/vacancies/?text=&search_text%nrstr(&)per_page=50"
	method = 'GET' 
	out = response;
run;

/* Подключаемся к JSON файлу с помощью движка JSON*/
libname hh JSON fileref=response;


/* SECTION-2. Опция Automap*/

/* Просмотр структуры импорта */
proc datasets lib=hh;
quit;

/* Создаем файл для хранения карты JSON*/
filename hh_jmap "&json_path\hh_resp.map";

libname hh JSON fileref=response map=hh_jmap automap=create;


/* SECTION-3. Чтение JSON по карте метаданных*/

/* Создаем файл для хранения пользовательской карты JSON*/
filename hh_vmap "&json_path\hh_vac.map";

libname hh JSON fileref=response map=hh_vmap;



