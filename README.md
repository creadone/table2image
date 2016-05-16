ePub :: table2image
==============

Скрипт позволяет избавиться от части боли и страданий, связанных с конвертацией ePub'ов в формат FB2. Ввиду терминальной убогости последнего приходится разбивать длинные таблицы на части и рендерить картинками в соответствии с css-стилями (используется css/bootstrap.css, правила можно переопределить в css/default.css). На выходе получится тот же самый ePub, но с отрендеренными в JPG таблицами и tidy-фицированным XHTML'ем. Скрипт подчищает за собой временные артефакты, но если он упал или вы его остановили сами, то перед следующим запуском нужно очистить от изображений директорию `tmpimages` и удалить `tmp`.

Скрипт переименовывает названия файлов в `input`. Если вам этого не нужно, закомментируйте с 39 по 43 строку.


Установка и запуск:
--------------

- `git clone https://github.com/creadone/table2image`
- `cd table2image`
- `bundle install`
- Добавить в директорию `input` ваши ePub'ы
- `bundle exec ruby table2image.rb`


TODO:
--------------

- Привести код в порядок, все написано на коленке за пару вечеров.
- Добавить обработку ошибок невалидных ePub'ов
- Расхардкодить путь к изображениям и брать его из content.opf
- Работать с системными tmp-папками
- Научиться резать картинки, а не сплитить HTML и рендерить его отдельно, потому что нерадивые верстаки могут запилить в `<td>` страницу текста.