package examples.helloworld;

import static junit.framework.Assert.assertEquals;
import org.junit.Test;

public class MainTest {

  @Test
  public void testRuleName() {
    KotlinLibraryRule rule = new KotlinLibraryRule(
      "foo",
      new java.util.ArrayList(),
      new java.util.ArrayList());

    assertEquals("foo", rule.getName());
  }

}
