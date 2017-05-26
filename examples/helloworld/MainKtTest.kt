package examples.helloworld

import kotlin.test.assertEquals
import org.junit.Test

public class MainKtTest {

  @Test fun testRuleName(): Unit {
    val rule = KotlinLibraryRule("foo", emptyList(), emptyList())
    assertEquals("foo", rule.name)
  }

}
