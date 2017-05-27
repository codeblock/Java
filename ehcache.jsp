<%@page 
/**
 * Ehcache management page
 * Ehcache 2.x based
 *
 * @author  beanfondue@gmail.com
 * @version 2.0
 * @see     http://www.ehcache.org/downloads/
 *          Ehcache 2.x
 * @see     Internet Connection needs for use the jQuery
 *          or Download it and modify declaration
 *          or replace to native JavaScript
 */
    language="java" 
    contentType="text/html;charset=UTF-8" 
    pageEncoding="UTF-8" 
    import="
         java.lang.reflect.Method
        ,java.lang.reflect.Modifier
        ,java.lang.reflect.InvocationTargetException
        
        ,java.io.File
        
        ,java.net.InetAddress
        ,java.net.URI
        ,java.net.UnknownHostException
        ,java.net.URISyntaxException
        
        ,java.rmi.RemoteException
        
        ,java.util.Arrays
        ,java.util.ArrayList
        ,java.util.Collection
        ,java.util.LinkedHashMap
        ,java.util.Iterator
        ,java.util.List
        ,java.util.Map
        ,java.util.TreeMap
        
        ,java.util.regex.Pattern
        ,java.util.regex.Matcher
        
        ,net.sf.ehcache.CacheManager
        ,net.sf.ehcache.Ehcache
        ,net.sf.ehcache.Element
        ,net.sf.ehcache.config.Configuration
        ,net.sf.ehcache.config.FactoryConfiguration
        ,net.sf.ehcache.distribution.ManualRMICacheManagerPeerProvider
        ,net.sf.ehcache.distribution.CacheManagerPeerProvider
        ,net.sf.ehcache.distribution.CachePeer
        ,net.sf.ehcache.CacheException 
    "
%>
<%!
public static final String LINE_NEW = System.getProperty("line.separator");
public static final String EMPTY_STRING = "";
public static final String SPACE = " ";
public static final String COMMA = ",";
public static final String COMMA_SPACE = COMMA + SPACE;
public static final String RMI_PREFIX = "//";
public static final String EHCACHE_CONFIG = System.getProperty("CONFIG_PATH") + File.separator + "ehcache.xml";
public static final CacheManager CACHE_MANAGER = CacheManager.create(EHCACHE_CONFIG);

public boolean isArray(final Object obj) {
    
    // --------------------------------------
    // Java Language Specification: http://docs.oracle.com/javase/specs/jls/se7/html/jls-10.html
    // Moreover: http://docs.oracle.com/javase/specs/jls/se7/html/jls-4.html#jls-4.3.1
    // Array Creation Expressions: http://docs.oracle.com/javase/specs/jls/se7/html/jls-15.html#jls-15.10
    // --------------------------------------
    
    if (obj == null) { return false; }
    String[] classes = {"java.lang.Cloneable", "java.io.Serializable"};
    Class[] impls = obj.getClass().getInterfaces();
    List list = Arrays.asList(classes);
    String obj_str = obj.toString();
    int i = 0, i_len = 0;
    int cnt = 0;
    for (i = 0, i_len = impls.length; i < i_len; i++) {
        if (list.contains(impls[i].getName())) {
            cnt++;
            // System.out.println(obj.getClass().getName() + " : " + impls[i].getName());
            if (cnt == classes.length) { break; }
        }
    }
    return cnt >= classes.length && ((obj_str.startsWith("[") && obj_str.endsWith("]")));
    // return cnt >= classes.length && ((obj_str.startsWith("[") && obj_str.endsWith("]")) || (obj_str.startsWith("{") && obj_str.endsWith("}")));
}

public boolean isKeyword(final Object obj) {
    boolean rtn = false;
    
    if (obj == null || ((obj instanceof Boolean) && (obj.equals(Boolean.TRUE) || obj.equals(Boolean.FALSE)))) {
        rtn = true;
    }
    
    return rtn;
}

public boolean isDefinedClass(final String cls) {
    boolean rtn = true;
    
    try {
        Class.forName(cls);
    } catch (Exception e) {
        rtn = false;
    }
    
    return rtn;
}

public boolean isDangerousMethod(String str) {
    boolean rtn = false;
    
    if (
            str.indexOf("clean") >= 0
         || str.indexOf("clear") >= 0
         || str.indexOf("clone") >= 0 // java.lang.CloneNotSupportedException
         || str.indexOf("delete") >= 0
         || str.indexOf("remove") >= 0
         || str.indexOf("reset") >= 0
    ) {
        rtn = true;
    }
    
    return rtn;
}

public static String getHostIP() {
    String rtn = "";
    
    try {
        InetAddress iaddr = InetAddress.getLocalHost();
        rtn = iaddr.getHostAddress();
    } catch (UnknownHostException e) {
        e.printStackTrace();
        rtn = e.getMessage();
    }
    
    return rtn;
}

public static Map appendPut(Map m, Object key, Object value) {
    List list = null, list_map = null;
    if (value instanceof ArrayList == false) {
        list = new ArrayList();
        list.add(value);
    } else {
        list = (ArrayList)value;
    }
    if (!m.containsKey(key)) {
        m.put(key, list);
    } else {
        list_map = (List)m.get(key);
        list_map.addAll(list);
    }
    return m;
}

public static LinkedHashMap getRemoteCachePeerInfos() throws URISyntaxException {
    LinkedHashMap rtn = new LinkedHashMap();
    rtn.put(getHostIP(), Arrays.asList(CACHE_MANAGER.getCacheNames()));
    
    Configuration cfg = CACHE_MANAGER.getConfiguration();
    List list_cfg = cfg.getCacheManagerPeerProviderFactoryConfiguration();
    Iterator iter = list_cfg.iterator();
    FactoryConfiguration fcfg = null;
    StringBuffer props_str = new StringBuffer();
    URI uri = null;
    
    int i = 0, i_len = 0;
    
    while (iter.hasNext()) {
        fcfg = (FactoryConfiguration)iter.next();
        props_str.append(fcfg.getProperties());
    }
    if (props_str.length() > 0) {
        Matcher matcher = Pattern.compile(".*?rmiUrls=([^,]+)(?:,.+)?$").matcher(props_str.toString());
        if (matcher.matches() == true && matcher.groupCount() == 1) {
            String[] matchers = matcher.group(1).split(" *\\| *");
            for (i = 0, i_len = matchers.length; i < i_len; i++) {
                uri = new URI(matchers[i]);
                appendPut(rtn, uri.getAuthority(), uri.getPath().replaceFirst("^/", ""));
            }
        }
    }
    
    return rtn;
}

public static List getRemoteCachePeerAddrs() throws URISyntaxException {
    return Arrays.asList(getRemoteCachePeerInfos().keySet().toArray());
}
    
public static List getRemoteCachePeerAddrKeys(String uri, String region, String search_key) throws URISyntaxException, RemoteException {
    List rtn = new ArrayList();
    
    CachePeer peer = null;
    Ehcache ehcache = null;
    LinkedHashMap lhm = getRemoteCachePeerInfos();
    List list = null;
    String regions = null, keys = null;
    List list_prov = null, list_el = null;
    
    int i = 0, i_len = 0;
    int j = 0, j_len = 0;
    int k = 0, k_len = 0;
    
    if (lhm.size() > 0) {
        CacheManagerPeerProvider provider = CACHE_MANAGER.getCacheManagerPeerProvider("RMI"); // RMI, JGROUPS, JMS
        
        if (lhm.containsKey(uri)) {
            list = (List)lhm.get(uri);
            for (i = 0, i_len = list.size(); i < i_len; i++) {
                regions = list.get(i).toString();
                if (regions.equals(region)) {
                    ehcache = CACHE_MANAGER.getEhcache(regions);
                    //System.out.println("region: " + region + ", provider: " + provider + ", ehcache: " + ehcache);
                    if (ehcache != null) {
                        list_prov = provider.listRemoteCachePeers(CACHE_MANAGER.getEhcache(regions));
                        for (j = 0, j_len = list_prov.size(); j < j_len; j++) {
                            peer = (CachePeer)list_prov.get(j);
                            if (peer.getUrlBase().equals(RMI_PREFIX + uri)) {
                                list_el = peer.getKeys();
                                for (k = 0, k_len = list_el.size(); k < k_len; k++) {
                                    keys = list_el.get(k).toString();
                                    if (search_key != null && !search_key.equals(EMPTY_STRING)) {
                                        if (keys.indexOf(search_key) > -1) {
                                            rtn.add(keys);
                                        }
                                    } else {
                                        rtn.add(keys);
                                    }
                                }
                            }
                        }
                    } else { // invalid regions
                    }
                }
            }
        }
    }
    
    //Object[] objs = rtn.toArray();
    //Arrays.sort(objs);
    //return Arrays.asList(objs);
    return rtn;
}

public static int getRemoteCachePeerAddrKeyCount(String uri, String region) throws URISyntaxException, RemoteException {
    int rtn = 0;
    
    CachePeer peer = null;
    Ehcache ehcache = null;
    LinkedHashMap lhm = getRemoteCachePeerInfos();
    List list = null;
    String regions = null, keys = null;
    List list_prov = null;
    
    int i = 0, i_len = 0;
    int j = 0, j_len = 0;
    int k = 0, k_len = 0;
    
    boolean counted = false;
    
    if (lhm.size() > 0) {
        CacheManagerPeerProvider provider = CACHE_MANAGER.getCacheManagerPeerProvider("RMI"); // RMI, JGROUPS, JMS
        
        if (lhm.containsKey(uri)) {
            list = (List)lhm.get(uri);
            for (i = 0, i_len = list.size(); i < i_len; i++) {
                regions = list.get(i).toString();
                if (regions.equals(region)) {
                    ehcache = CACHE_MANAGER.getEhcache(regions);
                    //System.out.println("region: " + region + ", provider: " + provider + ", ehcache: " + ehcache);
                    if (ehcache != null) {
                        list_prov = provider.listRemoteCachePeers(ehcache);
                        for (j = 0, j_len = list_prov.size(); j < j_len; j++) {
                            peer = (CachePeer)list_prov.get(j);
                            if (peer.getUrlBase().equals(RMI_PREFIX + uri)) {
                                rtn = peer.getKeys().size();
                                counted = true;
                                break;
                            }
                        }
                    } else { // invalid regions
                        rtn = -1;
                        counted = true;
                        break;
                    }
                }
                if (counted == true) { break; }
            }
        }
    }
    
    return rtn;
}

public String getMethodParams(Method mtd) {
    StringBuffer rtn = new StringBuffer();
    Class[] classes = mtd.getParameterTypes();
    
    int i, i_len;
    
    for (i = 0, i_len = classes.length; i < i_len; i++) {
        rtn.append(classes[i].getName()).append(COMMA_SPACE);
    }
    
    if (rtn.length() > COMMA_SPACE.length()) {
        rtn.setLength(rtn.length() - COMMA_SPACE.length());
    }
    
    return rtn.toString();
}

public String getObjectExploring(Object obj, int n) throws IllegalAccessException, InvocationTargetException {
    StringBuffer rtn = new StringBuffer();
    
    if (obj == null) {
        return rtn.toString();
    }
    
    Object obj_each;
    Collection collects;
    Method[] methods;
    Object[] obj_eachs;
    String obj_clsnm;
    String obj_each_clsnm;
    String method_params;
    String methods_rtntype_str;
    int i, i_len;
    int j, j_len;
    boolean obj_each_haschild;
    
    obj_clsnm = obj.getClass().getName();
    rtn.append(tabs(n) + "<span class=\"cache_val\">value</span>: " + obj.toString() + ": <span class=\"info\">" + obj_clsnm + "</span>").append(LINE_NEW);
    
    if (
            obj_clsnm.startsWith("java.lang")
         || obj_clsnm.indexOf("$") >= 0 // java.util.HashMap$KeyIterator -> interface java.util.Iterator -> java.lang.IllegalAccessException
    ) {
        return rtn.toString();
    }
    
    methods = obj.getClass().getDeclaredMethods();
    if (methods.length > 0) {
        rtn.append(tabs(n) + "<span class=\"cache_val\">method</span>: ").append(LINE_NEW);
        for (i = 0, i_len = methods.length; i < i_len; i++) {
            method_params = getMethodParams(methods[i]);
            methods_rtntype_str = methods[i].getReturnType().toString();
            rtn.append(tabs(n + 1) + methods[i].getName() + "(<span class=\"info_params\">" + method_params + "</span>): <span class=\"info\">" + methods_rtntype_str + "</span>").append(LINE_NEW);
            
            if (methods_rtntype_str.equals("void") || isDangerousMethod(methods[i].getName())) {
                continue;
            }
            if (Modifier.PUBLIC == methods[i].getModifiers() && method_params.length() == 0) {
                
                obj_each = null;
                try {
                    obj_each = methods[i].invoke(obj, null);
                } catch (InvocationTargetException e) {
                    //System.out.println(obj_clsnm + " : " + methods[i].getName() + " : " + methods[i].getModifiers());
                    rtn.append(tabs(n + 2)).append("<span class=\"exception\">").append(e.toString()).append("</span>").append(LINE_NEW);
                    continue;
                } catch (Exception e) {
                    //System.out.println(obj_clsnm + " : " + methods[i].getName() + " : " + methods[i].getModifiers());
                    rtn.append(tabs(n + 2)).append("<span class=\"exception\">").append(e.toString()).append("</span>").append(LINE_NEW);
                    continue;
                }
                obj_each_clsnm = (obj_each == null) ? EMPTY_STRING : obj_each.getClass().getName();
                obj_each_haschild = (obj_each == null) ? false : (
                    (
                        obj_each.toString().startsWith(obj_each_clsnm + "@")
                     && obj_each_clsnm.indexOf("[") < 0
                     && !obj_clsnm.equals(obj_each_clsnm)
                     // 1. type of class instance (ABC@18fe7c3)
                     // 2. ignore primitive class instance (getBytes() - [B@19f7)
                     // 3. ignore cloned object from same class
                    ) ? true : false
                );
                // rtn.append(tabs(n + 2) + "isarray: " + isArray(obj_each) + ", Object: " + obj_each + ", obj_each_clsnm: " + obj_each_clsnm + ", obj_each_haschild: " + obj_each_haschild).append(LINE_NEW);
                if (obj_each instanceof Iterator) {
                    Iterator iter = (Iterator)obj_each;
                    while (iter.hasNext()) {
                        rtn.append(getObjectExploring(iter.next(), (n + 2)));
                    }
                } else if (obj_each_haschild == true) {
                    rtn.append(getObjectExploring(obj_each, (n + 2)));
                } else {
                    if (isArray(obj_each)) {
                        collects = (Collection)obj_each;
                        if (collects != null) {
                            obj_eachs = collects.toArray();
                            for (j = 0, j_len = obj_eachs.length; j < j_len; j++) {
                                rtn.append(getObjectExploring(obj_eachs[j], (n + 2)));
                            }
                        }
                        //rtn.append("array: " + obj_each).append(LINE_NEW);
                    } else {
                        rtn.append(tabs(n + 2) + "<span class=\"cache_val\">value</span>: ");
                        if (isKeyword(obj_each)) {
                            rtn.append("<span class=\"tfn\">").append(obj_each).append("</span>").append(LINE_NEW);
                        } else {
                            rtn.append(obj_each).append(LINE_NEW);
                        }
                    }
                }
            }
        }
    }
    
    return rtn.toString();
}

public String tabs(int n) {
    StringBuffer sb = new StringBuffer();
    String tab = "\t";
    
    int i, i_len;
    
    n = Math.max(0, n);
    for (i = 0, i_len = n; i < i_len; i++) {
        sb.append(tab);
    }
    
    return sb.toString();
}
%>
<%
Object object = null;
Ehcache ehcache = null;
Element element = null;

int i = 0, i_len = 0;
int j = 0, j_len = 0;
int cnt = 0;

String str = null;
String cache_peer = getHostIP();
String cache_region = null;
String cache_key = null, cache_key_val = "";
String cache_rm = "";
if (request.getParameter("cache_peer") != null) {
    cache_peer = request.getParameter("cache_peer");
    if (cache_peer.equals(EMPTY_STRING)) { cache_peer = getHostIP(); }
}
if (request.getParameter("cache_region") != null) {
    cache_region = request.getParameter("cache_region");
    if (cache_region.equals(EMPTY_STRING)) { cache_region = null; }
}
if (!((List)getRemoteCachePeerInfos().get(cache_peer)).contains(cache_region)) {
    cache_region = null;
}

if (request.getParameter("cache_key") != null) {
    cache_key = request.getParameter("cache_key");
    cache_key_val = cache_key;
}
if (request.getParameter("cache_rm") != null) {
    cache_rm = request.getParameter("cache_rm");
}

String[] rm_caches = new String[] {};
if (cache_rm.equals("1") && request.getParameter("rm_caches") != null) {
    rm_caches = request.getParameterValues("rm_caches");
    if (cache_region != null && rm_caches.length > 0) {
        ehcache = CACHE_MANAGER.getEhcache(cache_region); // (Ehcache)map.get(cache_region);
        if (ehcache != null) {
            if (cache_peer.equals(getHostIP())) {
                for (i = 0, i_len = rm_caches.length; i < i_len; i++) {
                    //out.println(rm_caches[i] + "<br />");
                    ehcache.remove(rm_caches[i]);
                }
            } else {
                CacheManagerPeerProvider provider = CACHE_MANAGER.getCacheManagerPeerProvider("RMI");
                List list_prov = provider.listRemoteCachePeers(ehcache);
                CachePeer peer = null;
                for (i = 0, i_len = list_prov.size(); i < i_len; i++) {
                    peer = (CachePeer)list_prov.get(i);
                    if (peer.getUrlBase().equals(RMI_PREFIX + cache_peer)) {
                        for (j = 0, j_len = rm_caches.length; j < j_len; j++) {
                            //System.out.println(";;;" + rm_caches[j]);
                            peer.remove(rm_caches[j]);
                        }
                    }
                }
            }
        }
    }
}


//-------------------------------------
//String[] ehcache_names = CACHE_MANAGER.getCacheNames();
Object[] ehcache_names = ((List)getRemoteCachePeerInfos().get(cache_peer)).toArray();
Arrays.sort(ehcache_names);

List peer_addrs = getRemoteCachePeerAddrs();
Map map = new TreeMap();
Iterator iter = null;
String str_key = "", str_key_selected = "";

for (i = 0, i_len = ehcache_names.length; i < i_len; i++) {
    str = ehcache_names[i].toString();
    // out.println(ehcache_names[i] + "<br />");
    // map.put(ehcache_names[i], CACHE_MANAGER.getEhcache(ehcache_names[i]));
    if (cache_peer.equals(getHostIP())) {
        cnt = CACHE_MANAGER.getEhcache(str).getSize();
    } else {
        cnt = getRemoteCachePeerAddrKeyCount(cache_peer, str);
    }
    map.put(ehcache_names[i], cnt);
}
//-------------------------------------
iter = map.keySet().iterator();
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
        <title>Ehcache status</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <style type="text/css">
        * { margin: 0; padding: 0; font-family: Consolas, Courier; }
        html, body { width: 100%; height: 100%; font-size: 8pt; }
        .ta_c { text-align: center; }
        .container {
            width: 100%;
            height: 100%;
            position: relative;
        }
        .contents {
            left: 2%;
            top: 2%;
            width: 96%;
            height: 96%;
            position: relative;
        }
        .contents fieldset {
            border: 0;
        }
        .request {
            text-align: center;
        }
        .request h2 {
            font-family: Courier;
            font-size: 16pt;
        }
        .request * {
            vertical-align: middle;
        }
        .response {
            background-color: #efefef;
            border-radius: 0.5em;
            margin: 1.0em auto;
            padding: 1.0em;
        }
        .response input {
            padding: 0.2em;
        }
        .response input, .response label {
            vertical-align: middle;
        }
        .inputs {
            border: 1px solid #efefef;
            font-size: 8pt;
            padding: 0.4em;
        }
        select.inputs {
            border: 1px solid #efefef;
            font-size: 8pt;
            padding: 0.4em;
        }
        .equals { background-color: yellow; margin: 0; padding: 0; line-height: 0; }
        .cache_region { color: green; font-weight: bold; }
        .cache_key { color: #5ea549; }
        .cache_val { color: #d7552c; }
        .info { color: silver; }
        .info_params { color: #7bc67b; }
        /* .returns { color: #336699; } */
        .tfn { color: #b98620; font-style: italic; } /* true, false, null */
        .exception { color: red; font-style: italic; font-weight: bold; }
        .warning { color: red; font-style: italic; }
        .importance { color: red; }
        </style>
        <script type="text/javascript" src="http://code.jquery.com/jquery.min.js"></script>
        <script type="text/javascript">
        $(document).ready(function () {
            // $("ul.response > li").bind("mouseover", function () { $(this).css("background-color", "#f5f5f5"); });
            // $("ul.response > li").bind("mouseout", function () { $(this).css("background-color", ""); });
            $("#cache_key").select();
            $("#chk_on_off").bind('click', function () {
                var chk_on_off_flag = null;
                if ($(this).attr('bitvalue') == '0') {
                    chk_on_off_flag = true;
                    $(this).attr('bitvalue', '1');
                } else {
                    chk_on_off_flag = false;
                    $(this).attr('bitvalue', '0');
                }
                var val = $(this).attr('value');
                var val_r = $(this).attr('rvalue');
                
                $('input[name="rm_caches"]').each(function () {
                    this.checked = chk_on_off_flag;
                });
                
                $(this).attr('value', val_r);
                $(this).attr('rvalue', val);
            });
            $('#rm_on_chks').bind('click', function () {
                var chks_verify = false;
                $('#frm').find('input[name="rm_caches"]').each(function () {
                    if (this.checked == true) {
                        chks_verify = true;
                        return false;
                    }
                });
                if (chks_verify == true) {
                    $('#cache_rm').val('1');
                    $('#frm').submit();
                }
            });
        });
        </script>
    </head>
    <body>
        <div class="container">
            <div class="contents">
                <fieldset>
                    <form method="post" action="" id="frm">
                    <div class="request">
                        <h2>Ehcache search &amp; remove</h2>
                        <select name="cache_peer" class="inputs">
                            <%
                            for (i = 0, i_len = peer_addrs.size(); i < i_len; i++) {
                                str_key = peer_addrs.get(i).toString();
                                str_key_selected = str_key.equals(cache_peer) ? " selected=\"selected\"" : EMPTY_STRING;
                                if (str_key.equals(getHostIP())) {
                                    out.println("<option value=\"" + str_key + "\"" + str_key_selected + " class=\"importance\">" + str_key + "</option>");
                                } else {
                                    out.println("<option value=\"" + str_key + "\"" + str_key_selected + ">" + str_key + "</option>");
                                }
                            }
                            %>
                        </select>
                        <select name="cache_region" class="inputs">
                            <%
                            while (iter.hasNext()) {
                                //str = map.get(str_key).toString();
                                str_key = iter.next().toString();
                                str = map.get(str_key).toString();
                                str_key_selected = str_key.equals(cache_region) ? " selected=\"selected\"" : EMPTY_STRING;
                                //CACHE_MANAGER.getEhcache(
                                if (str.equals("-1")) { // invalid configuration for region
                                    out.println("<option value=\"" + str_key + "\"" + str_key_selected + " class=\"warning\">" + str_key + " - " + str + "</option>");
                                } else {
                                    out.println("<option value=\"" + str_key + "\"" + str_key_selected + ">" + str_key + " - " + str + "</option>");
                                }
                            }
                            %>
                        </select>
                        <input type="text" id="cache_key" name="cache_key" value="<%=cache_key_val%>" class="inputs" /> <input type="submit" value="search" class="inputs" /> 
                    </div>
                    <div class="btns">
                        <input type="hidden" id="cache_rm" name="cache_rm" value="" />
                        <input type="button" id="rm_on_chks" class="inputs" value="remove" /> 
                        <input type="button" id="chk_on_off" class="inputs" value="check all" rvalue="uncheck all" bitvalue="0" /> 
                    </div>
                    <div class="response">
                        <pre><%
            
            try {
                if (cache_peer != null && cache_region != null) {
                    out.println(tabs(0) + "<span class=\"cache_region\">&nbsp;&nbsp;host</span>: " + cache_peer);
                    out.println(tabs(0) + "<span class=\"cache_region\">region</span>: " + cache_region);
                    out.print(tabs(0) + "<span class=\"cache_region\">search</span>: ");
                    if (cache_key == null || cache_key.equals(EMPTY_STRING)) {
                        out.println(tabs(0) + "<span class=\"warning\">input keyword</span>");
                    } else {
                        out.println(tabs(0) + cache_key);
                    }
                    Object[] objs = null;
                    if (cache_peer.equals(getHostIP())) {
                        ehcache = CACHE_MANAGER.getEhcache(cache_region);
                        objs = ehcache.getKeys().toArray();
                    } else {
                        objs = getRemoteCachePeerAddrKeys(cache_peer, cache_region, cache_key).toArray();
                    }
                    Arrays.sort(objs);
                    String obj = "", obj_matches = "";
                    for (i = 0, i_len = objs.length; i < i_len; i++) {
                        obj = objs[i].toString();
                        obj_matches = obj;
                        
                        if (cache_key != null && !cache_key.equals(EMPTY_STRING)) { // if (cache_key != null && !obj.startsWith(cache_key))
                            if (obj.indexOf(cache_key) == -1) {
                                continue;
                            } else {
                                //obj_matches = obj_matches.replaceAll(cache_key, "<span class=\"equals\">" + cache_key + "</span>");
                                out.print(tabs(1) + "<input type=\"checkbox\" id=\"rm_" + obj + "\" name=\"rm_caches\" value=\"" + obj + "\" />");
                                out.println("<label for=\"rm_" + obj + "\"><span class=\"cache_key\">key</span>: " + obj_matches + "</label>");
                                if (cache_peer.equals(getHostIP())) {
                                    element = ehcache.get(obj);
                                    object = element.getObjectValue();
                                    out.println(getObjectExploring(object, 2));
                                    object = null;
                                }
                            }
                        }
                    }
                }
            } catch (CacheException err) {
                out.println(err.toString());
            }
                        %></pre>
                    </div>
                    </form>
                </fieldset>
            </div>
        </div>
    </body>
</html>