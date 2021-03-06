# health.rb

Отправляет статистику нод на https://stat.storj.maxrival.com.
Аналог https://github.com/AntonMZ/Storj-Utils/blob/master/health.sh,
только на Руби, без фатального недостатка и с немного ускоренным сбором данных.

Использование:
```
health.rb email [daemon address] [daemon port]
```

## Настройка автоматического запуска
### Через Крон
Поставить Руби (`apt-get install ruby`, `pacman -S ruby` и т.д. в зависимости от дистрибутива).

Дописать в кронтаб:
```
*/10 * * * * /path/to/script/health.rb example@mail.com
```

### Через виндовый шедулер (scheduler)
Скачать и поставить Руби (примерно отсюда https://www.ruby-lang.org/en/documentation/installation/#rubyinstaller).

Найти виндовый шедулер и запустить.

Создать новую задачу:
![0](https://user-images.githubusercontent.com/1857617/30785223-c1af0822-a16b-11e7-80b3-e3bfadb6304f.png)

Вписать какое-нибудь название и поменять "настроить для" (на всякий случай, м.б. не обязательно):
![1](https://user-images.githubusercontent.com/1857617/30785224-c46babb0-a16b-11e7-9702-5ccf047253c9.png)

На вкладке "триггеры" создать новый. Начало — при входе, пользователь — от чьего имени запускать (скорее всего текущий), повторять бесконечно каждые 10 (или 5) минут:
![2](https://user-images.githubusercontent.com/1857617/30785226-c6d4394e-a16b-11e7-8840-4a56287e358b.png)

Чтобы сработала задача "при входе", нужно перезайти. Для проверки можно сначала поставить триггер на изменение задачи:
![3](https://user-images.githubusercontent.com/1857617/30785227-c8e43c8e-a16b-11e7-9a88-ea3f8f9c3cad.png)

На вкладке "действия" создать новое. Программа — VBS-скрипт (НЕ .rb), аргумент — почта:
![4](https://user-images.githubusercontent.com/1857617/30785228-caeaeec4-a16b-11e7-9f27-42b3f5d27629.png)

VBS-скрипт нужен для того, чтоб health.rb запускался **молча**, т.е. не открывал консольное окно каждые 10 минут. А ещё он сохраняет рядом с собой логи работы основного скрипта.
