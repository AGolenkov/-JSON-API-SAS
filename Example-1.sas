/* Создаем временный файл для хранения ответа от API */
filename response temp;

/* Обращаемся к API и получаем ответ. В качестве примера используем API, возвращающее список людей в космосе*/
proc http 
	url='http://api.open-notify.org/astros.json'
	method = 'GET'
	out = response;
run;

/* Подключаемся к JSON файлу с помощью движка JSON*/
libname astro JSON fileref=response;

/* Отображаем результат в виде распечатки */
title "Кто сейчас в космосе? Дата: &sysdate9";

proc print data=astro.people;
var  name craft;
run;

title;