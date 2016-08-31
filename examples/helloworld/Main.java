package examples.helloworld;

// Not actually a necessary import since both in same package
import examples.helloworld.KotlinLibraryRule;

public class Main {
  public static void main(String[] args) {
    KotlinLibraryRule rule = new KotlinLibraryRule(
      "foo",
      new java.util.ArrayList(),
      new java.util.ArrayList());
    System.out.println("A bazel kotlin_library rule looks something like: ");
    System.out.println(rule.toString());
  }
}
