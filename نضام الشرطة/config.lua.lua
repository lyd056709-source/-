Config = {}

Config.Locale = 'ar' -- لغة السكربت (يمكنك إضافة ملفات ترجمة لاحقاً)

-- وظائف الشرطة المسموح بها للوصول إلى الميزات
Config.PoliceJobs = {
    'police',
    'sheriff',
    'swat'
}

-- إعدادات الأبواب (مثال: باب قسم الشرطة)
Config.DoorSettings = {
    -- يمكنك إضافة المزيد من الأبواب هنا
    {
        coords = vector3(450.45, -993.05, 30.69), -- إحداثيات الباب
        heading = 270.0,                           -- اتجاه الباب
        model = `v_ilev_ph_door02`,                -- موديل الباب (مهم للمزامنة)
        locked = true,                             -- هل هو مغلق افتراضياً؟
        authorizedJobs = Config.PoliceJobs,        -- الوظائف المصرح لها بفتحه
        label = 'باب قسم الشرطة الرئيسي',           -- اسم الباب الذي يظهر للاعب
        distance = 1.5                             -- المسافة التي يمكن للاعب التفاعل مع الباب منها
    },
    -- أضف المزيد من الأبواب هنا
}

-- إعدادات التصفيد (Cuffing)
Config.CuffTime = 5000 -- المدة بالمللي ثانية لتصفيد اللاعب (لإظهار الرسوم المتحركة)
Config.CuffItem = 'handcuffs' -- اسم العنصر الذي يمثل الكلبشات في ESX (إذا كنت تريد استهلاكها)

-- إعدادات الراديو
Config.RadioCommand = 'pradio' -- الأمر لفتح الراديو
Config.RadioChannel = 'police' -- القناة الافتراضية للراديو (يمكنك استخدام قنوات متعددة)

-- إعدادات التنبيهات (911)
Config.Alerts = {
    Enabled = true,
    NotificationTime = 10000, -- مدة بقاء التنبيه على الشاشة
    BlipTime = 60000,         -- مدة بقاء علامة الخريطة (blip)
    BlipSprite = 1,           -- شكل علامة الخريطة (راجع FiveM Blips)
    BlipColor = 3            -- لون علامة الخريطة
}

-- إعدادات التفاعل (القائمة التفاعلية)
Config.InteractionDistance = 2.0 -- المسافة للتفاعل مع اللاعبين الآخرين
Config.InteractionKey = 38       -- مفتاح التفاعل (E by default, 38 is E in GTA V keybinds)

-- إعدادات العناصر الممنوعة (للتفتيش)
Config.ContrabandItems = {
    'weed',
    'coke',
    'meth',
    'gun_pistol',
    'weapon_assaultrifle',
    'weapon_smg',
    -- أضف المزيد من العناصر الممنوعة هنا
}

-- رسائل السكربت (يمكنك إضافة المزيد هنا)
Config.Messages = {
    not_police = 'أنت لست ضابط شرطة!',
    door_locked = 'الباب مغلق.',
    door_unlocked = 'الباب مفتوح.',
    door_toggle = 'اضغط [~INPUT_CONTEXT~] لفتح/إغلاق الباب.',
    player_not_found = 'اللاعب غير موجود أو بعيد جداً.',
    cuffed = 'لقد تم تصفيدك.',
    uncuffed = 'لقد تم فك تصفيدك.',
    frisk_success = 'لقد قمت بتفتيش %s ووجدت: %s',
    frisk_empty = 'لقد قمت بتفتيش %s ولم تجد شيئاً مشبوهاً.',
    frisk_self = 'لا يمكنك تفتيش نفسك.',
    radio_sent = 'رسالة الراديو (%s): %s',
    radio_received = 'راديو الشرطة (%s): %s',
    alert_911 = 'تنبيه 911: %s في %s',
    player_not_cuffed = 'اللاعب ليس مصفداً.',
    item_taken = 'لقد أخذت %s من %s.',
    item_given = 'لقد أعطيت %s لـ %s.',
    no_handcuffs = 'ليس لديك كلبشات.',
}
