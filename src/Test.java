public class Test {
    public static void main(String[] args) {

        String s = "c70159b89b2a4938920dc7c84e8228b3";

        System.out.println(s.hashCode());
        System.out.println(s.hashCode() / 10);
        System.out.println(s.hashCode() / 10 % 10);
    }
}