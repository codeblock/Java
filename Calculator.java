/**
 * Calculation the formula
 * when lower than Java 1.6
 * 
 * @author  beanfondue@gmail.com
 * @version 1.0
 */

import java.util.regex.*;

class Calculator
{
    public static boolean isExistClass(String classname) {
        try {
            Class.forName(classname);
            return true;
        } catch (ClassNotFoundException e) {
            return false;
        }
    }
    
    private static String parseCalculate(String arg) throws Exception {
        int calc_in_start = arg.lastIndexOf("(");
        int calc_in_end   = 0;
        int i     = 0;
        int i_len = 0;
        String str_calc_in_end = "";
        
        if (calc_in_start > -1) {
            for (i = calc_in_start, i_len = arg.length(); i < i_len; i++) {
                str_calc_in_end = arg.substring(i, i + 1);
                if (")".equals(str_calc_in_end)) {
                    calc_in_end = i;
                    break;
                }
            }
            
            if (calc_in_start > -1 && calc_in_end > -1 && calc_in_start < calc_in_end) {
                String arg_in  = arg.substring(calc_in_start + 1, calc_in_end);
                double calc_in = extendedCalculate(arg_in);
                arg_in = arg_in.replaceAll("(-|\\+|\\*)", "\\\\$1"); // escape meta characters for regualr expression replacement (-, +, *). not(/, %)
                arg    = arg.replaceFirst("\\(" + arg_in + "\\)", String.valueOf(calc_in));
                
                return parseCalculate(arg);
            } else {
                return arg;
            }
        } else {
            return arg;
        }
    }
    
    private static double extendedCalculate(String arg) throws Exception {
        if (Pattern.matches(".*?[^-\\+\\d\\./%\\*\\(\\)\\s].*?", arg)) {
            throw new Exception("NaN");
        }
        
        arg = arg.replaceAll("\\s", "");
        arg = parseCalculate(arg);
        
        double rtn = 0;
        
        boolean debug = false;
        int i     = 0;
        int i_len = 0;
        boolean b = true;
        
        String as = arg.replaceAll("\\d+(?:\\.\\d+)?[/%\\*][-\\+]?\\d+(?:\\.\\d+)?(?:[/%\\*][-\\+]?\\d+(?:\\.\\d+)?)*", "?");
        String md = arg;
        
        int         rtn_md_len   = as.replaceAll("[^?]", "").length();
        double[]    rtn_md       = new double[rtn_md_len];
        int         rtn_md_index = 0;
        
        Pattern p_as = Pattern.compile("^([-\\+]?\\d+(?:\\.\\d+)?).*$");
        Pattern p_md = Pattern.compile(".*?(\\d+(?:\\.\\d+)?[/%\\*][-\\+]?\\d+(?:\\.\\d+)?(?:[/%\\*][-\\+]?\\d+(?:\\.\\d+)?)*).*?");
        Matcher m    = null;
        
        if (debug == true) {
            System.out.println("=========================================");
            System.out.println("as: " + as);
            System.out.println("md: " + md);
            System.out.println("md.length: " + as.replaceAll("[^?]", "").length());
            System.out.println("=========================================");
        }
        
        // ------------------------------------------------------------------------------- multiplication, division
        if (rtn_md_len > 0) {
            while (b == true) {
                m = p_md.matcher(md);
                if (m.matches()) {
                    double rtn_md_temp = 0;
                    String rtn_md_each = m.group(1);
                    String[] rtn_md_number = rtn_md_each.split("[/%\\*]");
                    String[] rtn_md_symbol = rtn_md_each.split("[-\\+]?\\d+(?:\\.\\d+)?");
                    
                    if (debug == true) {
                        System.out.println("rtn_md_each: " + rtn_md_each + ", rtn_md_symbol.length: " + rtn_md_symbol.length);
                    }
                    
                    for (i = 0, i_len = rtn_md_number.length; i < i_len; i++) {
                        
                        if (debug == true) {
                            System.out.println("rtn_md_number[" + i + "]: " + rtn_md_number[i] + ", rtn_md_symbol[" + i + "]: " + rtn_md_symbol[i]);
                        }
                        
                        if (i == 0) {
                            rtn_md_temp = Double.parseDouble(rtn_md_number[i]);
                        } else {
                            if ("*".equals(rtn_md_symbol[i])) {
                                rtn_md_temp *= Double.parseDouble(rtn_md_number[i]);
                            } else if ("/".equals(rtn_md_symbol[i])) {
                                rtn_md_temp /= Double.parseDouble(rtn_md_number[i]);
                            } else if ("*-".equals(rtn_md_symbol[i])) {
                                rtn_md_temp = 0 - rtn_md_temp * Math.abs(Double.parseDouble(rtn_md_number[i]));
                            } else if ("/-".equals(rtn_md_symbol[i])) {
                                rtn_md_temp = 0 - rtn_md_temp / Math.abs(Double.parseDouble(rtn_md_number[i]));
                            } else if ("%".equals(rtn_md_symbol[i])) {
                                rtn_md_temp %= Double.parseDouble(rtn_md_number[i]);
                            }
                        }
                    }
                    rtn_md[rtn_md_index++] = rtn_md_temp;
                    md = md.replaceFirst(p_md.pattern(), "");
                    
                    if (debug == true) {
                        System.out.println("-----------------------------------------");
                    }
                    
                } else {
                    b = false;
                }
            }
            
            for (i = 0, i_len = rtn_md.length; i < i_len; i++) {
                
                if (debug == true) {
                    System.out.println("rtn_md[" + i + "]: " + rtn_md[i]);
                }
                
                as = as.replaceFirst("\\?", String.valueOf(rtn_md[i]));
            }
            
            if (debug == true) {
                System.out.println("mounted calculate: " + as);
            }
        }
        
        b = true;
        
        // ------------------------------------------------------------------------------- addition, subtraction
        as = as.replaceAll("--", "+").replaceAll("\\+-", "-").replaceAll("-\\+", "-").replaceAll("\\+\\+", "+");
        //System.out.println("mounted calculate 2: " + as);
        
        while (b == true) {
            m = p_as.matcher(as);
            if (m.matches()) {
                //System.out.println(rtn + "::::" + as + "::::" + m.group(1));
                rtn += Double.parseDouble(m.group(1));
                as = as.replaceFirst("^([-\\+]?\\d+(?:\\.\\d+)?)", "");
            } else {
                b = false;
            }
        }
        
        return rtn;
    }

    public static double calculate(String formula) {
        double rtn = 0;
        
        try {
            rtn = extendedCalculate(formula);
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        return rtn;
    }

    public static void test(String[] args) throws Exception {
        //String formula = "1-2*(34*(2-22*3))";
        //String formula = "1-2*(34*(22-2*3))";
        
        // String formula = "1+(2+3)*3"; // 16
        // String formula = "1-2*34*(22-2)*3";
        // String formula = "1-22";
        // String formula = "1+(2+(3+4)*5)+(6+7)/8+(9+10)";
        // String formula = "1-2*(34*((2-22)*3))";
        // String formula = "1+2-3*4/(5+6-7)*8/9+10";
        //String formula = "1+1";
        
        //String formula = "1+2      *3 + ABC";
        String formula = "1+((2-3)*(4/(5+6-7*8)/9+10-1)*2)/((3+(4-5)*6/(7+(8-(9*10/1+(2-3)*(4/5+(6-7*8/9+(10-1*(2/3+(4-5))*6)/7)+8-9*10)/1+2)-3*4)/5)+6)-(7*(8/(9+10))))";
        //String formula = "1+((2-3)*(4/(5+6-7*8)/9+10-1)*2)/(3+(4-5)*6/(7+(8-(9*10/1+(2-3)*(4/5+(6-7*8/9+(10-1*(2/3+(4-5))*6)/7)+8-9*10)/1+2)-3*4)/5)+6)-7*8/9+10";
        //String formula = "1+((2-3)*(4/(5+6-7*8)/9+10-1)*2)/3+4-5*6/7+8-(9*10/1+(2-3)*(4/5+(6-7*8/9+(10-1*(2/3+(4-5))*6)/7)+8-9*10)/1+2)-3*4/5+6-7*8/9+10";
        //String formula = "9*10/1+(2-3)*(4/5+(6-7*8/9+(10-1*(2/3+(4-5))*6)/7)+8-9*10)";//-3*4/5+6-7*8/9+10";
        //String formula = "(4/5+(6-7*8/9+(10-1*(2/3+(4-5))*6)/7)+8-9*10)";
        //String formula = "(10-1*(2/3+(4-5))*6)";
        //String formula = "10-1*(2/3+(4-5))";
        
        double l = extendedCalculate(formula);
        
        System.out.println("*****************************************");
        System.out.println("formula-val: \"" + formula + "\"");
        
        if (isExistClass("javax.script.ScriptEngineManager")) {
            // using the standard (Java 1.6+) scripting library OR http://www.gnu.org/software/jel/
            // import ScriptEngineManager;
            // import javax.script.ScriptEngine;
            javax.script.ScriptEngineManager manager = new javax.script.ScriptEngineManager();
            javax.script.ScriptEngine engine = manager.getEngineByName("JavaScript");
            System.out.println("result-eval: " + engine.eval(formula));
        }
        
        System.out.println("result-mine: " + l);
        System.out.println("*****************************************");
    }
}