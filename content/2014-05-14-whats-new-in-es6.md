#ما الجديد في الإصدار القادم من JavaScript
Harmony هو الاسم الرمزي للإصدار السادس من لغة ECMAScript وهي اللغة القياسية التي تقوم عليها JavaScript، والإصدار الجديد يأتي بميزات جديدة تتناول العديد من جوانب اللغة بما فيها الصياغة (syntax) وأسلوب البناء وأنواع جديدة من المكونات المدمجة في اللغة. في هذا المقال نتعرف على بعض من المميزات التي ستجعل كتابة شيفرة JavaScript أكثر اختصاراً وفعالية.

##متغيرات نطاقها القطعة البرمجية (Block-scoped Variables)
في الإصدار الحالي من JavaScript، تُعامل كل المتغيرات المفروضة ضمن دالة (`function`) على أنها تابعة لهذه الدالة (Function-scoped) أي يمكن الوصول إليها من أي موقع ضمن هذه الدالة، حتى وإن كانت هذه المتغيرات قد فُرضِت ضمن قطعة برمجية فرعية ضمن هذه الدالة (كحلقة `for` أو جملة شرطية `if`)، وهذا يخالف ما تتبناه بعض من أشهر لغات البرمجة، وقد يسبب بعض الارتباك لمن لم يعتد عليه.
لنوضح أكثر في هذا المثال:

```javascript

var numbers = [1, 2, 3];
var doubles = [];

for (var i = 0; i < numbers.length; i++) {
   var num = numbers[i];
   doubles[i] = function() {
     console.log(num * 2);
   }
}

for (var j = 0; j < doubles.length; j++) {
  doubles[j]();
}

```

عند تنفيذ هذا المثال، سنحصل على الرقم `6` ثلاث مرات، وهو أمر غير متوقع ما لم نكن على معرفة بطبيعة مجالات JavaScript، ولو طبق ما يشبه هذا المثال في لغة أخرى، لحصلنا على النتيجة `2` ثم `4` ثم `6`، وهو ما يبدو النتيجة المنطقية لشيفرة كهذه.
ما الذي يحدث هنا؟ يتوقع المبرمج أن المتغير `num` محصور ضمن حلقة `for` وعليه فإن الدالة التي ندخلها في المصفوفة `doubles` ستعطي عند استدعائها القيمة التي ورثتها عن مجال حلقة `for` إلا أن الحقيقة هي أن المتغير `num` يتبع للمجال العام، لأن حلقة `for` لا تُنشئ مجالًا فرعيًّا وعليه فإن القيمة العامة `num` تتغير ضمن حلقة `for` من `2` إلى `4` إلى `6` وعند استدعاء أي دالة ضمن المصفوفة `doubles` فإنها ستعيد إلينا القيمة العامة `num`، وبما أن الاستدعاء يحدث بعد إسناد آخر قيمة للمتغير `num`، فإن قيمته في أي لحظة بعد انتهاء الحلقة الأولى ستكون آخر قيمة أسندت إليه ضمن هذه الحلقة، وهي القيمة `6`.

يعطينا الإصدار القادم طريقة لحل هذا الارتباك باستخدام الكلمة المفتاحية `let` بدلاً عن `var`، وهي تقوم بخلق مجال ضمن القطعة البرمجية التي تُستخدم فيها، بمعنى آخر: ستكون `let` هي بديلنا عن `var` من الآن فصاعدًا، لأنها ببساطة تعطينا النتائج البديهية التي نتوقعها. لنُعِد كتابة المثال السابق باستبدال `var num` بـ`let num`:

```javascript
var numbers = [1, 2, 3];
var doubles = [];

for (var i = 0; i < numbers.length; i++) {
   let num = numbers[i];
   doubles[i] = function() {
     console.log(num * 2);
   }
}

for (var j = 0; j < doubles.length; j++) {
  doubles[j]();
}
```

عند تطبيق هذا المثال (يمكنك تطبيقه في Firefox وChrome لأن كلا المتصفحين بدأا بدعم `let`) سنحصل على النتيجة البديهية `2` ثم `4` ثم `6`. بالطبع بإمكاننا تحسين الشيفرة باعتماد `let` عند التصريح عن كل المتغيرات السابقة، وهو الأمر الذي يجب أن تعتاد فعله من اليوم!

##شيفرة أقصر وأسهل للقراءة

لعل أكثر ما أُحبّه في JavaScript مرونتها الفائقة، وبالذات القدرة على إمرار دوال مجهولة (Anonymous Functions) لدوال أخرى، الأمر الذي يسمح لنا بكتابة شيفرة ما كان من الممكن كتابتها بلغات أخرى إلا بضعفي عدد الأسطر وربما أكثر. لاحظ هذا المثال:

```javascript
var people = ['Ahmed', 'Samer', 'Khaled'];
var greetings = people.map(function(person) { return 'Hello ' + person + '!'; });

console.log(greetings); // ['Hello Ahmed!', 'Hello Samer!', 'Hello Khaled!'];
```

لو أردنا تنفيذ هذه المهمة في لغة أخرى، فلربما احتجنا إلى حلقة `for` لنمرّ من خلالها على كل عنصر ضمن المصفوفة ثم إدخال العبارات الجديدة ضمن مصفوفة أخرى، وهذا يعني أن مهمة يمكن كتابتها بسطرين في JavaScript قد تتطلب 5 سطور في لغة أخرى. لو لم تمتلك JavaScript القدرة على إمرار الدالة المجهولة `function(person) {...}` أعلاه، لفقدت جزءًا كبيرة من مرونتها.

لكن الإصدار القادم من JavaScript تذهب أبعد من ذلك، وتختصر علينا كتابة الكثير من النص البرمجي. لُنعد كتابة المثال السابق:

```javascript
let people = ['Ahmed', 'Samer', 'Khaled'];
let greetings = people.map(person => 'Hello ' + person + '!');

console.log(greetings); // ['Hello Ahmed!', 'Hello Samer!', 'Hello Khaled!'];
```

في هذا المثال استخدمنا ما اصطلح على تسميته **دوال الأسهم (Arrow Functions)**، وهي طريقة أكثر اختصارًا لكتابة الدوال المجهولة، لن تحتاج لكتابة `return`، فهي ستضاف تلقائيًا عند التنفيذ. من الآن فصاعداً اعتمد دوال الأسهم عندما تريد تنفيذ دالة مجهولة بسيطة بسطر واحد.

بمناسبة الحديث عن الشيفرة المختصرة... ما رأيكم لو جعلنا الشيفرة أعلاه _أكثر اختصارًا_؟!

```javascript
let people = ['Ahmed', 'Samer', 'Khaled'];
let greetings = ['Hello ' + person + '!' for (person of people)];

console.log(greetings); // ['Hello Ahmed!', 'Hello Samer!', 'Hello Khaled!'];
```

قد تبدو الصياغة غريبة بعض الشيء، لكنها تتيح لنا فهم النص بسهولة أكبر، وتغنينا عن الحاجة لدالة مجهولة (الأمر الذي قد يؤثر على الأداء، وإن كان بأجزاء من الثواني). الصياغة التي استخدمناها أعلاه تُسمى **Array Comprehensions**، وإن كنت قادرًا على ترجمتها إلى العربية بطريقة واضحة، فلا تبخل بها علينا!

لكن... ألا ترون أنه يمكن تحسين هذه الشيفرة قليلاً؟

```javascript
let people = ['Ahmed', 'Samer', 'Khaled'];
let greetings = [`Hello ${ person }!` for (person of people)];

console.log(greetings); // ['Hello Ahmed!', 'Hello Samer!', 'Hello Khaled!'];
```
هنا استبدلنا إشارات الاقتباس (`'` أو `"`) بالإشارة \` الأمر الذي أتاح لنا إحاطة المتغير `person` بقوسين معكوفين مسبوقين بإشارة `$`، وهذه الصياغة تدعى **"السلاسل النصية المقولبة"** أو Template Strings، والتي تسمح -بالإضافة إلى القولبة- بالعديد من الأشياء الرائعة، كالعبارات على عدة أسطر:

```javascript
let multilineString = `I am
a multiline
string`;
  
console.log(multilineString);
// I am
// a multiline
// string

```

للأسف لن تعمل الشفرة السابقة في أي من المتصفحات الحالية، لأن السلاسل النصية المقولبة ما تزال غير معتمدة ضمن أي منها.

من المميزات الجديدة كذلك إمكانية اختصار بناء الكائنات ذات الخصائص بالشكل التالي:

  * حاليًا، نقوم بكتابة شيفرة مثل هذه:

  ```javascript
    var createPerson = function(name, age, location) {
      return {
        name: name,
        age: age,
        location: location,
        greet: function() {
          console.log('Hello, I am ' + name + ' from ' + location + '. I am ' + age + '.');
        }
      }
    };
    
    var fawwaz = createPerson('Fawwaz', 21, 'Syria');
    console.log(fawwaz.name); // 'Fawwaz'
    fawwaz.greet(); // "Hello, I am Fawwaz from Syria. I am 21."
  ```
  * في الإصدار القادم، سيكون بالإمكان كتابة الشيفرة كالتالي:

  ```javascript
    let createPerson = function(name, age, location) {
      return {
        name,
        age,
        location,
        greet() {
          console.log('Hello, I am ' + name + ' from ' + location + '. I am ' + age + '.');
        }
      }
    };
    
    let fawwaz = createPerson('Fawwaz', 21, 'Syria');
    console.log(fawwaz.name); // 'Fawwaz'
    fawwaz.greet(); // "Hello, I am Fawwaz from Syria. I am 21."
  ```

بما أن اسم المُعامل (parameter) يماثل اسم الخاصة (property)، فإن هذا يتم تفسيره على أن قيمة الخاصة توافق قيمة المعامل، بمعنى: `name: name`، بالإضافة إلى كتابة `greet() {...}` بدل `greet: function() {...}`.

كذلك سيكون بإمكاننا تحسين هذا النص أكثر من ذلك باستخدام **الأصناف (Classes)**، نعم! سيكون لدينا أصناف أخيرًا! (سنستعرضها لاحقاً)

##الثوابت (Constants)
سيداتي وسادتي... رحبوا بالثوابت... نعم إنها أخيرًا متوفرة في JavaScript، إحدى المكونات الأساسية لأي لغة برمجية التي لم تكن متوفرة في JavaScript، أصبحت الآن متوفرة. والآن نأتي للسؤال البديهي: لماذا أحتاج للثوابت؟ أليس بإمكاني التصريح عن متغير دون أن أغير قيمته بعد إعطاءه القيمة الأولية؟ نعم بالطبع بإمكانك ذلك، لكن هذا لا يعني بالضرورة أن المستخدم أو نصاً برمجيًا من طرف ثالث ليس بإمكانه تغيير قيمة هذا المتغير في سياق التنفيذ، وطالما أن المتغير "متغير" بطبيعته، فإننا دومًا بحاجة إلى شيء من أصل اللغة يحمينا من تغييره خطأ. عند التصريح عن ثابت فإننا نعطيه قيمة أولية ثم ستتولى الآلة البرمجية لـJavaScript حماية هذا الثابت من التغيير، وسُيرمى خطأ عند محاولة إسناد قيمة جديدة لهذا الثابت.

```javascript
const myConstant = 'Never change this!';

myConstant = 'Trying to change your constant';
// TypeError: redeclaration of const myConstant

console.log(myConstant); // "Never change this!"
```

##المُعاملات الافتراضية (Default Parameters)
غياب دعم المُعاملات الافتراضية في JavaScript واحد من أكثر الأشياء التي تزعجني، لأنها تجبرني على كتابة شيفرة مثل هذه:

```javascript
function SayHello (user) {
  if (typeof user == 'undefined') {
    user = 'User';
  }
  
  console.log('Hello ' + user);
}

console.log(SayHello('Fawwaz')); // Hello Fawwaz!
console.log(SayHello()); // Hello User!
```

لو كان عندي 3 متغيرات غير إجبارية، فهذا يعني أنني سأحتاج 3 جمل شرطية، الأمر الذي يتطلب الكثير من الكتابة المُملة. بفضل الإصدار القادم من JavaScript، سيكون بالإمكان كتابة شيفرة أبسط بكثير:

```javascript
function SayHello (user='User') {
  console.log('Hello ' + user);
}

SayHello('Fawwaz'); // Hello Fawwaz!
SayHello(); // Hello User!
```

##`this` القاموسية

##المُولِّدات (Generators)
المولدات ببساطة هي دوال يمكن إيقافها والعودة إليها في وقت لاحق مع الاحتفاظ بسياقها دون تغيير، صياغة المولدات لا تختلف كثيرًا عن صياغة الدوال التقليدية، كل ما عليك هو إضافة إشارة * بعد `function` واستخدام `yield` بدل `return`، المثال التالي سيوضح فكرة المولدات أكثر:

```javascript
function* getName() {
  let names = ['Muhammad', 'Salem', 'Abdullah'];
  for (name of names) {
    yield name;
  }
}
  
let myGenerator = getName();
myGenerator.next().value; // 'Muhammad'
myGenerator.next().value; // 'Salem'
myGenerator.next().value; // 'Abdullah'
myGenerator.next().value; // undefined

}
```
ما الذي يحدث هنا؟ فرضنا مولّدًا سمّيناه `getName`، وفيه صرحنا عن مصفوفة فيها أسماء، وظيفة هذا المولد أن يعطينا الأسماء بالترتيب في كل مرة نستدعيه فيها ليعطينا النتيجة التالية (`next()`)، أولاً يجب حفظ نسخة عن المولّد ضمن متغير لكي نسمح لها بحفظ حالتها، ودون ذلك سيعطينا استدعاء المولد مباشرة `getName().next()` دوماً النتيجة الأولى لأننا عملياً نُنشئ نسخة جديدة عنه في كل مرة نستدعيه، أما استدعاء نسخة عنه وحفظها في متغير مثل `myGenerator` فيسمح لنا باستدعاء `.next()` عليها كما هو متوقع. لا ترجع الدالة `.next()` القيمة التي نرسلها عبر `yield` فقط، بل ترجع كائناً يحوي القيمة المطلوبة ضمن الخاصة `value`، وخاصة أخرى `done` تسمح لنا بمعرفة ما إذا كان المولد قد أعطانا كل شيء (يجب استدعاء `next()` مرة واحدة زائدة عن العدد الذي نتوقعه للحصول على `done` بقيمة `true`، لأنه لا يمكن منطقيًا معرفة ما إذا أنهى المولّد عمله في الخطوة التي تسبق الخطوة الأخيرة - أليس كذلك؟).

تبدو المولدات فكرة جميلة... وهي تسهل عمل مُكررات دون الحاجة لتلويث النطاق بمتغيرات مثل هذه:

```javascript
var i = -1;
function getName() {
  var names = ['Muhammad', 'Salem', 'Abdullah'];
  i++;
  return names[i];
}

getName(); // 'Muhammad'
getName(); // 'Salem'
getName(); // 'Abdullah'
getName(); // undefined

```

ترتيب أكثر للشيفرة، ولكن ما الفائدة _الحقيقية_ للمولدات؟ هل حزرتها؟ نعم... **المهمات غير المتزامنة (Asynchronus Tasks)**! لحظة... ما العلاقة بين هذه وتلك؟

لنلقِ نظرة... لنفترض أنني أريد جلب بيانات من الخادم..

```javascript
$.ajax('http')
// TODO
```

##المُكرِّرات (Iterators)

##البقيّة (Rest) والناشرة (Spread)

##التفكيك Destructuring

##حلقة `for... of`

##الوحدات (Modules)

##الأصناف (Classes)

##أشباه المصفوفات Set وMap وWeakMap

##الوعود (Promises)
الوعود هي الحل الذي تأتينا به JavaScript لحل مشكلة هرم الموت (Pyramid of Death) الذي نواجهه عند تنفيذ مهمات غير متزامنة تعتمد إحداها على الأخرى:

```javascript
function getFullPost(url, callback) {
  
  var getAuthor = function(post, callback) {
    $.ajax({ method: 'GET', url: '/author/' + post.author_id }, callback);
  };
  
  var getRelatedPosts = function(post, callback) {
    $.ajax({ method: 'GET', url: '/related/' + post.id }, callback);
  };
  
  $.ajax({ method: 'GET', url: url }, function(post) {
    getAuthor(post, function(res) {
      post.author = res.data.author;
      getRelatedPosts(post, function(res) {
        post.releated = res.data.releated;
        callback(post);
      });
    });
  });
  
}
```

هل تلاحظ أن الشيفرة تتجه نحو اليمين؟ لو أردنا تنفيذ هذه المهمات غير المتزامنة واحدة بعد الأخرى وكان عددها 10 مثلًا فستصبح الشيفرة شديدة التعقيد، كما أن هذه الطريقة ليست بديهية، ولا يمكن لك أن تفهم ماذا تفعل هذه الدالة المجهولة (المعامل الثاني في كل دالة) ما لم تألفها. ماذا لو أمكننا كتابة هذه الشيفرة بصورة أفضل؟

```javascript
function getFullPost(url) {
  var post = { };
  var getPost = function(url) {
    return $http.get(url);
  };
  
  var getAuthor = function(post) {
    return $http.get('/author/' + post.author_id).then(function(res) {
      post.author = res.data.author;
    });
  };
  
  var getRelatedPosts = function(post) {
    return $http.get('/related/' + post.id).then(function(res) {
        post.related = res.data.related;
    });
  };
  
  return getPost().then(getAuthor).then(getRelatedPosts).catch(function(err) {
    console.log('We got an error:', err);
  });
}
```

##المُفوّضات (Proxies)

