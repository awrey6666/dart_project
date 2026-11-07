import 'content_store.dart';
import 'learn_models.dart';

const groupProgramming = 'Ծրագրավորում և տեղեկատվական տեխնոլոգիաներ';
const groupEnglish = 'Անգլերեն լեզու';
const groupMath = 'Մաթեմատիկա';
const groupOther = 'Այլ ուսումնական առարկաներ';

/// Խմբերի ստանդարտ հերթականությունը (նոր խմբերը ավելանում են վերջում)։
const defaultGroups = [groupProgramming, groupEnglish, groupMath, groupOther];

/// Ներկառուցված (սկզբնական) կատալոգը։ Ադմինի փոփոխությունները պահվում են
/// [ContentStore]-ում, և հավելվածի մնացած մասը օգտագործում է [learnSubjects]-ը։
const builtinSubjects = <LearnSubject>[
  // ---------------- Ծրագրավորում և IT ----------------
  LearnSubject(
    id: 'dart',
    title: 'Dart',
    group: groupProgramming,
    colorValue: 0xFF0175C2,
    codeLanguage: 'Dart',
    topics: [
      Topic(
        id: 'dart.vars',
        subjectId: 'dart',
        title: 'Փոփոխականներ և տիպեր',
        tip:
            'Dart-ում փոփոխականը հայտարարվում է var, final կամ const բառով։ '
            'final-ին արժեք վերագրվում է մեկ անգամ, const-ը հաստատուն է արդեն կոմպիլյացիայի պահին։ '
            'Հիմնական տիպերն են՝ int, double, String, bool։ Տիպից հետո ? նշանը թույլ է տալիս null։',
      ),
      Topic(
        id: 'dart.cond',
        subjectId: 'dart',
        title: 'Պայմաններ',
        tip:
            'if / else if / else-ը ընտրում է գործողության ճանապարհ։ Պայմանը պետք է լինի bool։ '
            '&& նշանակում է «և», || նշանակում է «կամ», ! նշանակում է «ոչ»։ '
            'Կարճ տարբերակ՝ պայման ? ա : բ, իսկ null-ի համար՝ ??։',
      ),
      Topic(
        id: 'dart.loops',
        subjectId: 'dart',
        title: 'Ցիկլեր',
        tip:
            'for (սկիզբ; պայման; քայլ) կրկնում է մարմինը, քանի դեռ պայմանը true է։ '
            'while-ը ստուգում է պայմանը նախքան կրկնությունը։ break-ը դուրս է գալիս ցիկլից, '
            'continue-ն բաց է թողնում ընթացիկ քայլը։ Քայլ առ քայլ գրեք փոփոխականների արժեքները։',
      ),
      Topic(
        id: 'dart.funcs',
        subjectId: 'dart',
        title: 'Ֆունկցիաներ',
        tip:
            'Ֆունկցիան ունի վերադարձի տիպ, անուն և պարամետրեր՝ int add(int a, int b) { return a + b; }։ '
            'Կարճ գրելաձև՝ => (arrow)։ Անվանված պարամետրերը գրվում են {} փակագծերում։ '
            'Եթե ոչինչ չի վերադարձվում, տիպը void է։',
      ),
    ],
  ),
  LearnSubject(
    id: 'java',
    title: 'Java',
    group: groupProgramming,
    colorValue: 0xFFE76F00,
    codeLanguage: 'Java',
    topics: [
      Topic(
        id: 'java.basics',
        subjectId: 'java',
        title: 'Տիպեր և օպերատորներ',
        tip:
            'Java-ն ստատիկ տիպավորված է՝ int, double, boolean, char, String։ '
            'Ամբողջ թվերի բաժանումը կտրում է մնացորդը (7 / 2 = 3), % -ը տալիս է մնացորդը։ '
            'String-ները համեմատեք equals()-ով, ոչ թե ==-ով։',
      ),
      Topic(
        id: 'java.oop',
        subjectId: 'java',
        title: 'Դասեր և օբյեկտներ',
        tip:
            'Դասը օբյեկտի նախագիծն է, օբյեկտը՝ դրա օրինակը (new)։ '
            'private դաշտերը թաքցնում են տվյալները (ինկապսուլյացիա), ժառանգումը գրվում է extends-ով։ '
            'Java-ում դասը ժառանգում է միայն մեկ դասից։',
      ),
    ],
  ),
  LearnSubject(
    id: 'js',
    title: 'JavaScript',
    group: groupProgramming,
    colorValue: 0xFFF7B500,
    codeLanguage: 'JavaScript',
    topics: [
      Topic(
        id: 'js.basics',
        subjectId: 'js',
        title: 'Հիմունքներ',
        tip:
            'Օգտագործեք let և const (var-ը հնացած է)։ === համեմատում է առանց տիպի ավտոմատ փոխարկման, '
            '== ՝ փոխարկումով։ typeof-ը ցույց է տալիս տիպը։ Թվերը float են, ուստի 0.1 + 0.2 ≠ 0.3։',
      ),
      Topic(
        id: 'js.func',
        subjectId: 'js',
        title: 'Ֆունկցիաներ և զանգվածներ',
        tip:
            'Arrow ֆունկցիա՝ (a, b) => a * b։ Զանգվածի մեթոդներ՝ push (ավելացնել), '
            'map (փոխակերպել յուրաքանչյուրը), filter (ընտրել պայմանով), reduce (հավաքել մեկ արժեքի)։',
      ),
    ],
  ),
  LearnSubject(
    id: 'csharp',
    title: 'C#',
    group: groupProgramming,
    colorValue: 0xFF68217A,
    codeLanguage: 'C#',
    topics: [
      Topic(
        id: 'cs.basics',
        subjectId: 'csharp',
        title: 'Հիմունքներ',
        tip:
            'C#-ում տպում ենք Console.WriteLine()-ով։ Տիպերը՝ int, double, string, bool, var (տիպը դուրս է բերվում ինքնաբերաբար)։ '
            'foreach (var x in list) անցնում է հավաքածուի բոլոր տարրերով։',
      ),
      Topic(
        id: 'cs.oop',
        subjectId: 'csharp',
        title: 'Դասեր և ժառանգում',
        tip:
            'Դասը գրվում է class, ժառանգումը՝ class B : A։ Հատկությունը՝ public int Age { get; set; }։ '
            'interface-ը պայմանագիր է, virtual/override-ը թույլ են տալիս պոլիմորֆիզմ։',
      ),
    ],
  ),
  LearnSubject(
    id: 'web',
    title: 'HTML և CSS',
    group: groupProgramming,
    colorValue: 0xFFE34F26,
    codeLanguage: 'HTML/CSS',
    topics: [
      Topic(
        id: 'web.html',
        subjectId: 'web',
        title: 'HTML',
        tip:
            'HTML-ը նկարագրում է էջի կառուցվածքը թեգերով՝ <h1> վերնագիր, <p> պարբերություն, '
            '<a href> հղում, <img src> նկար, <ul><li> ցուցակ։ Էջը սկսվում է <!DOCTYPE html>-ով։',
      ),
      Topic(
        id: 'web.css',
        subjectId: 'web',
        title: 'CSS',
        tip:
            'CSS-ը տալիս է տեսքը՝ սելեկտոր { հատկություն: արժեք; }։ .կլաս, #id։ '
            'Box model՝ content → padding → border → margin։ display: flex-ը դասավորում է էլեմենտները շարքով։',
      ),
    ],
  ),
  LearnSubject(
    id: 'sql',
    title: 'Տվյալների բազաներ և SQL',
    group: groupProgramming,
    colorValue: 0xFF00758F,
    codeLanguage: 'SQL',
    topics: [
      Topic(
        id: 'sql.select',
        subjectId: 'sql',
        title: 'SELECT հարցումներ',
        tip:
            'SELECT սյուներ FROM աղյուսակ WHERE պայման ORDER BY սյուն։ '
            'COUNT, SUM, AVG, MIN, MAX ագրեգատ ֆունկցիաներ են։ WHERE-ը զտում է տողերը, HAVING-ը՝ խմբերը։',
      ),
      Topic(
        id: 'sql.join',
        subjectId: 'sql',
        title: 'JOIN և բանալիներ',
        tip:
            'JOIN-ը միացնում է աղյուսակները ընդհանուր բանալիով (ON a.id = b.a_id)։ '
            'INNER JOIN՝ միայն համընկնումները, LEFT JOIN՝ ձախ աղյուսակի բոլոր տողերը։ '
            'PRIMARY KEY-ը եզակի է, FOREIGN KEY-ը հղվում է այլ աղյուսակի բանալուն։',
      ),
    ],
  ),
  LearnSubject(
    id: 'ds',
    title: 'Տվյալագիտություն',
    group: groupProgramming,
    colorValue: 0xFF3776AB,
    codeLanguage: 'Python/pandas',
    topics: [
      Topic(
        id: 'ds.stats',
        subjectId: 'ds',
        title: 'Վիճակագրության հիմունքներ',
        tip:
            'Միջին = գումար / քանակ։ Մեդիանը դասավորված շարքի միջին տարրն է։ Մոդան ամենահաճախ արժեքն է։ '
            'Արտաքին շեղումները խիստ ազդում են միջինի վրա, բայց ոչ մեդիանի։',
      ),
      Topic(
        id: 'ds.pandas',
        subjectId: 'ds',
        title: 'Տվյալների մշակում (pandas)',
        tip:
            'pandas-ի DataFrame-ը աղյուսակ է։ df.head() ցույց է տալիս առաջին տողերը, df.describe()՝ վիճակագրություն, '
            'df.dropna()՝ հեռացնում է բացակա արժեքները, df.groupby()՝ խմբավորում է։',
      ),
    ],
  ),
  LearnSubject(
    id: 'algo',
    title: 'Ալգորիթմներ և տրամաբանություն',
    group: groupProgramming,
    colorValue: 0xFF455A64,
    topics: [
      Topic(
        id: 'algo.complexity',
        subjectId: 'algo',
        title: 'Բարդություն',
        tip:
            'Բարդությունը ցույց է տալիս, թե քայլերի քանակը ինչպես է աճում n-ի հետ։ '
            'O(1) < O(log n) < O(n) < O(n log n) < O(n²)։ Մեկ ցիկլը՝ O(n), ներդրված երկու ցիկլը՝ O(n²)։',
      ),
      Topic(
        id: 'algo.sorting',
        subjectId: 'algo',
        title: 'Տեսակավորում և որոնում',
        tip:
            'Bubble sort-ը համեմատում է հարևանները՝ O(n²)։ Merge sort-ը բաժանում և միավորում է՝ O(n log n)։ '
            'Binary search-ը կիսում է տեսակավորված զանգվածը ամեն քայլին՝ O(log n)։',
      ),
    ],
  ),

  // ---------------- Անգլերեն ----------------
  LearnSubject(
    id: 'english',
    title: 'Անգլերեն',
    group: groupEnglish,
    colorValue: 0xFFC62828,
    codeLanguage: null,
    topics: [
      Topic(
        id: 'en.grammar',
        subjectId: 'english',
        title: 'Քերականություն',
        tip:
            'Present Simple՝ he/she/it + բայ + s (she goes)։ Past Simple՝ բայ + ed կամ անկանոն ձև (see → saw)։ '
            'since՝ կետ ժամանակի մեջ (since 2015), for՝ ժամանակահատված (for 5 years)։ '
            'a/an՝ an դրվում է ձայնավորի ձայնի առաջ։',
      ),
      Topic(
        id: 'en.vocab',
        subjectId: 'english',
        title: 'Բառապաշար և նախադասություններ',
        tip:
            'Բառերը սովորեք զույգերով՝ հոմանիշ/հականիշ։ Հարցական նախադասության կարգը՝ '
            'հարցական բառ + օժանդակ բայ + ենթակա + գլխավոր բայ (Where do you live?)։ '
            'Ընթերցելիս նախ գտեք հիմնական տեղեկությունը։',
      ),
    ],
  ),

  // ---------------- Մաթեմատիկա ----------------
  LearnSubject(
    id: 'math',
    title: 'Մաթեմատիկա',
    group: groupMath,
    colorValue: 0xFF1565C0,
    topics: [
      Topic(
        id: 'math.arith',
        subjectId: 'math',
        title: 'Թվաբանություն',
        tip:
            'Գործողությունների կարգը՝ փակագծեր, բազմապատկում/բաժանում, գումարում/հանում։ '
            'p%-ը n-ից՝ n · p / 100։ Մեծ թվերը բաժանեք հեշտ մասերի (12 · 15 = 12 · 10 + 12 · 5)։',
      ),
      Topic(
        id: 'math.algebra',
        subjectId: 'math',
        title: 'Հանրահաշիվ',
        tip:
            'Հավասարումը լուծելիս նույն գործողությունը կատարեք երկու կողմերում։ '
            'Օրինակ՝ 3x − 5 = 16 → 3x = 21 → x = 7։ Սխալ չլինելու համար տեղադրեք x-ը և ստուգեք։',
      ),
      Topic(
        id: 'math.geometry',
        subjectId: 'math',
        title: 'Երկրաչափություն',
        tip:
            'Ուղղանկյան մակերես՝ a · b, պարագիծ՝ 2(a + b)։ Պյութագորաս՝ c² = a² + b²։ '
            'Շրջանի մակերես՝ π r²։ Եռանկյան անկյունների գումարը 180° է։',
      ),
      Topic(
        id: 'math.logic',
        subjectId: 'math',
        title: 'Տրամաբանական խնդիրներ',
        tip:
            'Շարքերում փնտրեք օրինաչափություն՝ հաստատուն տարբերություն (+d), հաստատուն հարաբերություն (·q) '
            'կամ աճող տարբերություն։ Խնդիրը բաժանեք փոքր քայլերի և ստուգեք արդյունքը։',
      ),
    ],
  ),

  // ---------------- Այլ առարկաներ ----------------
  LearnSubject(
    id: 'physics',
    title: 'Ֆիզիկա',
    group: groupOther,
    colorValue: 0xFF6A1B9A,
    topics: [
      Topic(
        id: 'phys.mech',
        subjectId: 'physics',
        title: 'Մեխանիկա',
        tip:
            'Արագություն՝ v = s / t։ Նյուտոնի երկրորդ օրենք՝ F = m · a (ուժը չափվում է նյուտոններով)։ '
            'Ազատ անկման արագացումը մոտ 9,8 մ/վ² է և կախված չէ զանգվածից (վակուումում)։',
      ),
      Topic(
        id: 'phys.elec',
        subjectId: 'physics',
        title: 'Էլեկտրականություն',
        tip:
            'Օհմի օրենք՝ I = U / R։ Հզորություն՝ P = U · I։ Միավորներ՝ լարում՝ վոլտ (Վ), հոսանք՝ ամպեր (Ա), '
            'դիմադրություն՝ օհմ, հզորություն՝ վատտ (Վտ)։',
      ),
    ],
  ),
  LearnSubject(
    id: 'chemistry',
    title: 'Քիմիա',
    group: groupOther,
    colorValue: 0xFF2E7D32,
    topics: [
      Topic(
        id: 'chem.basics',
        subjectId: 'chemistry',
        title: 'Հիմունքներ',
        tip:
            'Ատոմի կարգաթիվը հավասար է պրոտոնների քանակին (C՝ 6, O՝ 8)։ Ջուրը H₂O է, կերակրի աղը՝ NaCl։ '
            'pH 7՝ չեզոք, pH < 7՝ թթվային, pH > 7՝ հիմնային։',
      ),
      Topic(
        id: 'chem.reactions',
        subjectId: 'chemistry',
        title: 'Ռեակցիաներ',
        tip:
            'Ռեակցիայի ժամանակ ատոմների թիվը պահպանվում է, դրա համար ռեակցիան հավասարեցնում ենք գործակիցներով։ '
            'Թթու + հիմք → աղ + ջուր։ Կալցիումի կարբոնատը տաքացնելիս քայքայվում է։',
      ),
    ],
  ),
  LearnSubject(
    id: 'biology',
    title: 'Կենսաբանություն',
    group: groupOther,
    colorValue: 0xFF00838F,
    topics: [
      Topic(
        id: 'bio.cell',
        subjectId: 'biology',
        title: 'Բջիջ',
        tip:
            'Միջուկը պահում է ԴՆԹ-ն, միտոքոնդրիումը արտադրում է էներգիա, քլորոպլաստը կատարում է ֆոտոսինթեզ '
            '(միայն բույսերում), ռիբոսոմը սինթեզում է սպիտակուց։',
      ),
      Topic(
        id: 'bio.human',
        subjectId: 'biology',
        title: 'Մարդու մարմին',
        tip:
            'Սիրտը չորս խոռոչ ունի և մղում է արյունը։ Թոքերում արյունը հարստանում է թթվածնով։ '
            'D վիտամինը սինթեզվում է մաշկում արևի լույսի ազդեցությամբ։',
      ),
    ],
  ),
  LearnSubject(
    id: 'history',
    title: 'Պատմություն',
    group: groupOther,
    colorValue: 0xFF5D4037,
    topics: [
      Topic(
        id: 'hist.armenia',
        subjectId: 'history',
        title: 'Հայոց պատմություն',
        tip:
            'Կարևոր տարեթվեր՝ Էրեբունի՝ մ.թ.ա. 782, քրիստոնեությունը պետական կրոն՝ 301, '
            'հայոց այբուբեն՝ 405, Ավարայրի ճակատամարտ՝ 451։ Դասավորեք իրադարձությունները ժամանակագրությամբ։',
      ),
      Topic(
        id: 'hist.world',
        subjectId: 'history',
        title: 'Համաշխարհային պատմություն',
        tip:
            'Ֆրանսիական հեղափոխություն՝ 1789, Առաջին համաշխարհային պատերազմ՝ 1914–1918, '
            'Երկրորդ համաշխարհային պատերազմ՝ 1939–1945, Կոստանդնուպոլսի անկում՝ 1453։',
      ),
    ],
  ),
  LearnSubject(
    id: 'geography',
    title: 'Աշխարհագրություն',
    group: groupOther,
    colorValue: 0xFF558B2F,
    topics: [
      Topic(
        id: 'geo.world',
        subjectId: 'geography',
        title: 'Աշխարհ',
        tip:
            'Ամենամեծ օվկիանոսը Խաղաղն է։ Ամենաբարձր լեռը Էվերեստն է։ Նեղոսը հոսում է Եգիպտոսով։ '
            'Մայրցամաքներից ամենամեծը Ասիան է, երկրորդը՝ Աֆրիկան։',
      ),
      Topic(
        id: 'geo.armenia',
        subjectId: 'geography',
        title: 'Հայաստան',
        tip:
            'Հայաստանի ամենամեծ լիճը Սևանն է (Գեղարքունիքի մարզ)։ Ամենաբարձր կետը Արագածն է։ '
            'Հրազդան գետը հոսում է Երևանով։ Հարևաններն են՝ Վրաստան, Ադրբեջան, Իրան, Թուրքիա։',
      ),
    ],
  ),
  LearnSubject(
    id: 'economics',
    title: 'Տնտեսագիտություն',
    group: groupOther,
    colorValue: 0xFFEF6C00,
    topics: [
      Topic(
        id: 'econ.basics',
        subjectId: 'economics',
        title: 'Հիմնական հասկացություններ',
        tip:
            'ՀՆԱ՝ երկրում արտադրված ապրանքների և ծառայությունների արժեք։ Գնաճի ժամանակ փողի գնողունակությունը նվազում է։ '
            'Հնարավորության արժեք՝ լավագույն հրաժարված այլընտրանքի արժեքը։',
      ),
      Topic(
        id: 'econ.market',
        subjectId: 'economics',
        title: 'Շուկա և գներ',
        tip:
            'Պահանջարկ՝ գնորդների ցանկությունը, առաջարկ՝ վաճառողների պատրաստակամությունը։ '
            'Հավասարակշռության գինը այն է, որտեղ պահանջարկը հավասար է առաջարկին։ '
            'Զեղչ p%՝ գին · (1 − p/100)։',
      ),
    ],
  ),
  LearnSubject(
    id: 'armenian',
    title: 'Հայոց լեզու',
    group: groupOther,
    colorValue: 0xFFAD1457,
    topics: [
      Topic(
        id: 'hy.grammar',
        subjectId: 'armenian',
        title: 'Խոսքի մասեր',
        tip:
            'Գոյականը պատասխանում է «ով՞/ի՞նչ» հարցին, ածականը՝ «ինչպիսի՞», բայը՝ «ի՞նչ է անում», '
            'թվականը՝ «քանի՞»։ Ժամանակակից այբուբենը 39 տառ ունի։',
      ),
      Topic(
        id: 'hy.spelling',
        subjectId: 'armenian',
        title: 'Նախադասություն և կետադրություն',
        tip:
            'Հայերենում վերջակետը «։» է, ստորակետը՝ «՝», հարցականը՝ «՞» (դրվում է շեշտված ձայնավորի վրա)։ '
            'Նախադասությունը ունի ենթակա և ստորոգյալ։',
      ),
    ],
  ),
  LearnSubject(
    id: 'russian',
    title: 'Ռուսերեն լեզու',
    group: groupOther,
    colorValue: 0xFF1E88E5,
    topics: [
      Topic(
        id: 'ru.grammar',
        subjectId: 'russian',
        title: 'Քերականություն',
        tip:
            'Ռուսերենում 6 հոլով կա՝ Именительный (кто? что?), Родительный (кого? чего?), Дательный (кому? чему?), '
            'Винительный (кого? что?), Творительный (кем? чем?), Предложный (о ком? о чём?)։ '
            'Անցյալ ժամանակում բայը փոխվում է ըստ սեռի՝ читал / читала։',
      ),
      Topic(
        id: 'ru.vocab',
        subjectId: 'russian',
        title: 'Բառապաշար',
        tip:
            'Սովորեք բառերը զույգերով (рус. ↔ հայ.) և օգտագործեք նախադասության մեջ։ '
            'Հականիշներ՝ большой ↔ маленький, быстрый ↔ медленный։',
      ),
    ],
  ),
];

/// Ընթացիկ կատալոգը՝ ներկառուցվածը կամ ադմինի խմբագրածը։
List<LearnSubject> get learnSubjects => ContentStore.instance.subjects;

/// Առարկաների խմբերը՝ ստանդարտ հերթականությամբ, հետո նորերը։
List<String> get learnGroups => ContentStore.instance.groups;

Topic? builtinTopicById(String id) {
  for (final subject in builtinSubjects) {
    for (final topic in subject.topics) {
      if (topic.id == id) return topic;
    }
  }
  return null;
}

LearnSubject? subjectById(String id) {
  for (final subject in learnSubjects) {
    if (subject.id == id) return subject;
  }
  return null;
}

Topic? topicById(String id) {
  for (final subject in learnSubjects) {
    for (final topic in subject.topics) {
      if (topic.id == id) return topic;
    }
  }
  return null;
}
