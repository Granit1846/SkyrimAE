// Внутри MovieClip "MainMenu"
function init():void {
    // Заголовок
    title.text = "Меню быстрого запуска Twitch Dragonborn Legacy";
    subtitle.text = "Выберите раздел меню";

    // Кнопки
    btnForce.addEventListener(MouseEvent.CLICK, onForceClick);
    btnChaos.addEventListener(MouseEvent.CLICK, onChaosClick);
    btnInventory.addEventListener(MouseEvent.CLICK, onInventoryClick);
    btnShow.addEventListener(MouseEvent.CLICK, onShowClick);
    btnVirus.addEventListener(MouseEvent.CLICK, onVirusClick);
    btnTeleport.addEventListener(MouseEvent.CLICK, onTeleportClick);
    btnCharacteristic.addEventListener(MouseEvent.CLICK, onCharacteristicClick);
    btnGigant.addEventListener(MouseEvent.CLICK, onGigantClick);

    // Назад
    btnBack.visible = false;
}

function onForceClick(e:MouseEvent):void {
    gotoPage("Force");
}

function onChaosClick(e:MouseEvent):void {
    gotoPage("Chaos");
}

function onInventoryClick(e:MouseEvent):void {
    gotoPage("Inventory");
}

function onShowClick(e:MouseEvent):void {
    gotoPage("Show");
}

function onVirusClick(e:MouseEvent):void {
    gotoPage("Virus");
}

function onTeleportClick(e:MouseEvent):void {
    gotoPage("Teleport");
}

function onCharacteristicClick(e:MouseEvent):void {
    gotoPage("Characteristic");
}

function onGigantClick(e:MouseEvent):void {
    gotoPage("Gigant");
}

function gotoPage(pageName:String):void {
    // Скрываем текущий экран
    this.visible = false;

    // Открываем новый экран
    var page:MovieClip = parent.getChildByName(pageName) as MovieClip;
    if (page) {
        page.visible = true;
        page.init();
    }
}