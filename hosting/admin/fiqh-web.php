<?php
declare(strict_types=1);
require_once __DIR__.'/fiqh-public.php';

const FIQH_WEB_ORIGIN='https://quran.abdulrahmanalsaeed.com';
function fiqhWebEscape(string $value):string
{
    return htmlspecialchars($value,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');
}
function fiqhWebPath(string $lang,string $slug=''):string
{
    if (!in_array($lang,['ar','en'],true)||($slug!==''&&!fiqhStableId($slug))) throw new InvalidArgumentException('Invalid page path');
    return '/admin/fiqh/'.$lang.'/'.($slug===''?'':rawurlencode($slug).'/');
}
function fiqhWebText(mixed $value,string $lang):string
{
    $text=fiqhPublicBi($value)[$lang]; return fiqhWebEscape($text);
}
function fiqhWebParagraph(string $label,mixed $value,string $lang):string
{
    $text=fiqhWebText($value,$lang);
    return $text===''?'':'<section><h3>'.fiqhWebEscape($label).'</h3><p>'.nl2br($text,false).'</p></section>';
}
function fiqhWebList(string $label,array $items,string $lang):string
{
    $out='';
    foreach ($items as $item) { $text=fiqhWebText($item,$lang); if ($text!=='') $out.='<li>'.$text.'</li>'; }
    return $out===''?'':'<section><h3>'.fiqhWebEscape($label).'</h3><ul>'.$out.'</ul></section>';
}
function fiqhWebPage(array $catalog,string $lang,string $slug=''):?string
{
    $ar=$lang==='ar'; $other=$ar?'en':'ar';
    $tr=static fn(string $a,string $b):string=>$ar?$a:$b;
    $e='fiqhWebEscape';
    $issue=null;
    if ($slug!=='') {
        foreach ($catalog['issues'] as $row) if ($row['slug']===$slug) { $issue=$row; break; }
        if ($issue===null) return null;
    }
    $title=$issue===null?$tr('الفقه المقارن','Comparative Fiqh'):$issue['title'][$lang];
    $description=$issue===null?$catalog['disclaimer'][$lang]:$issue['summary'][$lang];
    $canonical=FIQH_WEB_ORIGIN.fiqhWebPath($lang,$slug);
    $alternate=FIQH_WEB_ORIGIN.fiqhWebPath($other,$slug);
    $out='<!doctype html><html lang="'.$lang.'" dir="'.($ar?'rtl':'ltr').'"><head><meta charset="utf-8">'
        .'<meta name="viewport" content="width=device-width, initial-scale=1"><title>'.$e($title).' | مدار الهدى</title>'
        .'<meta name="description" content="'.$e($description).'"><link rel="canonical" href="'.$e($canonical).'">'
        .'<link rel="alternate" hreflang="'.$lang.'" href="'.$e($canonical).'"><link rel="alternate" hreflang="'.$other.'" href="'.$e($alternate).'">'
        .'<meta property="og:type" content="'.($issue===null?'website':'article').'"><meta property="og:title" content="'.$e($title).'">'
        .'<meta property="og:description" content="'.$e($description).'"><meta property="og:url" content="'.$e($canonical).'">'
        .'<link rel="stylesheet" href="/admin/fiqh-public.css"></head><body><header><nav><a href="/">'.$tr('مدار الهدى','Madar Al-Huda').'</a>'
        .' <a href="'.$e(fiqhWebPath($lang)).'">'.$tr('الفقه المقارن','Comparative Fiqh').'</a>'
        .' <a hreflang="'.$other.'" lang="'.$other.'" href="'.$e(fiqhWebPath($other,$slug)).'">'.$tr('English','العربية').'</a></nav></header>'
        .'<main><h1>'.$e($title).'</h1><aside>'.$e($catalog['disclaimer'][$lang]).'</aside>';
    if ($issue===null) {
        if ($catalog['issues']===[]) $out.='<p>'.$tr('لا توجد مسائل منشورة بعد.','No published issues yet.').'</p>';
        foreach ($catalog['categories'] as $category) {
            $items=array_filter($catalog['issues'],fn($i)=>$i['categoryId']===$category['id']||($i['subcategoryId'] ?? null)===$category['id']);
            if (!$items) continue;
            $out.='<section><h2>'.fiqhWebText($category['title'],$lang).'</h2><ul>';
            foreach ($items as $row) $out.='<li><a href="'.$e(fiqhWebPath($lang,$row['slug'])).'">'.fiqhWebText($row['title'],$lang).'</a></li>';
            $out.='</ul></section>';
        }
    } else {
        $out.='<p><bdi>'.$e($issue['number']).' · v'.$issue['revision'].'</bdi></p>';
        foreach (['summary'=>$tr('الملخص','Summary'),'introduction'=>$tr('المقدمة','Introduction'),'scope'=>$tr('نطاق المسألة','Scope')] as $key=>$label)
            $out.=fiqhWebParagraph($label,$issue[$key],$lang);
        $out.='<h2>'.$tr('المذاهب الأربعة','The four schools').'</h2><div class="schools">';
        foreach (['hanafi'=>$tr('الحنفي','Hanafi'),'maliki'=>$tr('المالكي','Maliki'),'shafii'=>$tr('الشافعي','Shafi‘i'),'hanbali'=>$tr('الحنبلي','Hanbali')] as $key=>$name) {
            $p=$issue['positions'][$key];
            $out.='<article><h2>'.$name.'</h2>';
            foreach (['ruling'=>$tr('القول','Position'),'explanation'=>$tr('الشرح','Explanation'),'reasoning'=>$tr('التعليل','Reasoning'),'classification'=>$tr('التصنيف','Classification')] as $field=>$label)
                $out.=fiqhWebParagraph($label,$p[$field],$lang);
            foreach (['conditions'=>$tr('الشروط','Conditions'),'exceptions'=>$tr('الاستثناءات','Exceptions'),'alternativeOpinions'=>$tr('أقوال أخرى','Other opinions')] as $field=>$label)
                $out.=fiqhWebList($label,$p[$field],$lang);
            foreach ($p['sourceReferences'] as $ref) {
                $source=(array)$issue['sources'];
                $name=fiqhWebText($source[$ref['sourceId']]['title'] ?? null,$lang);
                $out.='<p>'.$name.' — '.fiqhWebText($ref['locator'],$lang).'</p>';
            }
            $out.='</article>';
        }
        $out.='</div><h2>'.$tr('الأدلة','Evidence').'</h2>';
        foreach ($issue['evidence'] as $entry) {
            $out.='<article>';
            foreach (['text'=>$tr('نص الدليل','Evidence text'),'reference'=>$tr('المرجع','Reference'),'explanation'=>$tr('الشرح','Explanation'),'grading'=>$tr('درجة الحديث','Hadith grading'),'gradingAttribution'=>$tr('نسبة الحكم','Grading attribution')] as $key=>$label)
                $out.=fiqhWebParagraph($label,$entry[$key],$lang);
            if (isset($entry['quranLocator'])) {
                $q=$entry['quranLocator'];
                $out.='<p>'.$tr('السورة والآيات','Surah and verses').': <bdi>'.$q['surah'].':'.$q['firstAyah'].'–'.$q['lastAyah'].'</bdi></p>';
            }
            if (isset($entry['hadithLocator'])) {
                $h=$entry['hadithLocator']; $source=(array)$issue['sources'];
                $out.='<p>'.fiqhWebText($source[$h['collectionSourceId']]['title'] ?? null,$lang).'</p>';
                foreach (['number'=>$tr('الرقم','Number'),'book'=>$tr('الكتاب','Book'),'chapter'=>$tr('الباب','Chapter'),'editionLocator'=>$tr('الطبعة والموضع','Edition and locator')] as $key=>$label)
                    $out.=fiqhWebParagraph($label,$h[$key],$lang);
            }
            if (isset($entry['url'])) $out.='<p><a rel="noopener noreferrer" href="'.$e($entry['url']).'">'.$tr('رابط المصدر','Source link').'</a></p>';
            $out.='</article>';
        }
        foreach (['agreements'=>$tr('مواضع الاتفاق','Agreement'),'disagreements'=>$tr('مواضع الاختلاف','Disagreement'),'reasonsForDifferences'=>$tr('أسباب الاختلاف','Reasons for differences')] as $key=>$label) {
            $block=$issue[$key];
            $out.=$block['applicable']?fiqhWebList($label,$block['entries'],$lang):fiqhWebParagraph($label,$block['justification'],$lang);
        }
        $out.=fiqhWebParagraph($tr('الخلاصة العلمية','Scholarly summary'),$issue['scholarlySummary'],$lang);
        foreach (['practicalExamples'=>$tr('أمثلة','Examples'),'importantNotes'=>$tr('تنبيهات','Notes'),'terminology'=>$tr('مصطلحات','Terminology')] as $key=>$label)
            $out.=fiqhWebList($label,$issue[$key],$lang);
        $out.='<h2>'.$tr('المراجع','Sources').'</h2><ul>';
        foreach ((array)$issue['sources'] as $source) {
            $out.='<li>'.fiqhWebText($source['title'],$lang).' — '.fiqhWebText($source['author'],$lang);
            foreach (['publisher','edition','publicationYear','volume','pages'] as $key)
                if (isset($source[$key])) $out.=' · '.$e((string)$source[$key]);
            $out.='</li>';
        }
        $out.='</ul>';
    }
    return $out.'</main></body></html>';
}
function fiqhWebSitemap(array $catalog):string
{
    $out='<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';
    foreach (['ar','en'] as $lang) {
        $out.='<url><loc>'.FIQH_WEB_ORIGIN.fiqhWebPath($lang).'</loc></url>';
        foreach ($catalog['issues'] as $issue)
            $out.='<url><loc>'.FIQH_WEB_ORIGIN.fiqhWebPath($lang,$issue['slug']).'</loc></url>';
    }
    return $out.'</urlset>';
}
function serveFiqhWeb(PDO $db,mixed $page,mixed $slug):never
{
    $method=$_SERVER['REQUEST_METHOD'] ?? 'GET';
    header('Cache-Control: no-cache');
    header("Content-Security-Policy: default-src 'none'; style-src 'self'; base-uri 'none'; frame-ancestors 'none'");
    if (!in_array($method,['GET','HEAD'],true)) { header('Allow: GET, HEAD'); http_response_code(405); exit; }
    if (!is_string($page)||!is_string($slug)||!in_array($page,['ar','en','sitemap'],true)
        ||($slug!==''&&!fiqhStableId($slug))||($page==='sitemap'&&$slug!=='')||!fiqhPublicEnabled($db)) {
        http_response_code(404); header('X-Robots-Tag: noindex'); exit;
    }
    $catalog=fiqhPublicCatalog($db);
    if ($page==='sitemap') {
        header('Content-Type: application/xml; charset=utf-8'); $body=fiqhWebSitemap($catalog);
    } else {
        header('Content-Type: text/html; charset=utf-8'); $body=fiqhWebPage($catalog,$page,$slug);
        if ($body===null) { http_response_code(404); header('X-Robots-Tag: noindex'); exit; }
    }
    if ($method==='GET') echo $body;
    exit;
}
