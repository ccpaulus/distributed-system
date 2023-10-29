public class ClassLoaderTest {


    public static void main(String[] args) {
        ClassLoader currentClassLoader = ClassLoaderTest.class.getClassLoader();
        System.out.println(currentClassLoader);
        System.out.println(currentClassLoader.getParent());
        System.out.println(currentClassLoader.getParent().getParent());
    }


}
