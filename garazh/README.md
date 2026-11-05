# Гараж

Гонка друзей. У каждого свой бетонный бокс: свет из окон, подъёмник, верстак, седан на полу. Деньги только гоночные. Четыре доработки — скорость, разгон, держак, масса — меняют массу, трение шин и момент на колёсах. Цвет кузова скорость не меняет. Лёгкая машина быстрее на прямой и свободнее в дуге, тяжёлая держит поворот и проигрывает старт.

Кнопка **Выехать** везёт на личный полигон: прямая, дуга, круг. После круга видны разгон, максимум и держак. Выплаты на полигоне нет.

**Гонка с друзьями:** до 4 человек, которые уже на этом сервере гаража. Сервер снимает взнос и вызывает `TeleportService:ReserveServer` + `TeleportToPrivateServer` на плейс гонки. 3 круга, победитель забирает банк, остальные получают небольшое участие, кнопка **Реванш**. Перед стартом видны сборки соперников.

## Заглушка

Призрачный круг не пишется и не проигрывается. Кнопка отвечает текстом и ничего не сохраняет. Полигон и гонка с приглашением в коде есть.

## Rojo

Папка, которую открывать: `garazh` (в репозитории это `/workspace/garazh`).

Нужны [Rojo](https://rojo.space/) 7 и плагин Rojo в Studio.

Гараж (лобби и бокс):

```bash
cd garazh
rojo serve default.project.json
```

В Studio: Rojo → Connect. Сохранить плейс и опубликовать его в universe.

Плейс гонки (отдельное окно Studio или после Disconnect):

```bash
cd garazh
rojo serve race.project.json
```

Опубликовать гонку **в тот же universe**. В `src/shared/Config.luau` вписать `RACE_PLACE_ID` и `GARAGE_PLACE_ID`. Пока там `0`, приглашение честно отказывается и взнос не снимает.

`ReserveServer` и `TeleportToPrivateServer` проверяются только на опубликованном плейсе. В Studio резерв сервера не работает: это не баг сборки. Плейс гонки в Studio можно запустить отдельно — круг и реванш идут, денег он не платит.

DataStore `GarazhProfile_v1` вызывается только на опубликованном сервере. В Studio и в неопубликованном месте сервис не трогается: Play не останавливается на ошибке DataStore, деньги и доработки живут в памяти до конца сессии. Стартовые 500 кр. — чтобы купить доработку и выехать на полигон без друга.

## Арт

Кузов — официальный седан Roblox (модель 6418239833): краска, стекло, фары и колёса из мешей. Пол гаража — бетон, стены — бетон, подъёмник — металл. Это не шоурум и не машина из кирпичей.

## English

Friends’ race. Open the `garazh` folder with Rojo: `rojo serve default.project.json` for the garage place, `rojo serve race.project.json` for the race place. Connect the Rojo plugin in Studio. The car uses the public Roblox sedan meshes (model 6418239833), with concrete, asphalt, and metal in the garage. Not a finished showroom. `TeleportService:ReserveServer` only works on a published race place in the same universe — put both place ids in `src/shared/Config.luau`. Studio Play does not call DataStore; cash and upgrades stay in memory for the session. The solo ghost lap is a stub. The garage, car, four upgrades, proving pad, and invited race are in code.
