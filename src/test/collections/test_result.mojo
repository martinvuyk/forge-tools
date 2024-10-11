# RUN: %mojo %s

from testing import assert_true, assert_false, assert_equal
from collections import Dict
from forge_tools.collections.result import Result, Result2, Error2


fn _returning_err[T: CollectionElement](value: T) raises -> Result[T]:
    result = Result[T](err=Error("something"))
    if not result:
        return result
    raise Error("shouldn't get here")


fn _returning_ok[T: CollectionElement](value: T) raises -> Result[T]:
    result = Result[T](value)
    if result:
        return result
    raise Error("shouldn't get here")


fn _returning_transferred_err[
    T: CollectionElement
](value: T) raises -> Result[T]:
    # this value and err at the same time will never happen, just for testing
    # the value "some other string" should NOT get transferred
    res1 = Result(String("some other string"))
    res1.err = Error("some error")
    if res1:
        return res1
    raise Error("shouldn't get here")


fn _returning_none_err[T: CollectionElement](value: T) raises -> Result[T]:
    res1 = Result[String](err=Error("some error"))
    if res1.err:
        return None, res1.err
    raise Error("shouldn't get here")


def test_none_err_constructor():
    res1 = _returning_none_err(String("some string"))
    assert_true(not res1 and res1.err and str(res1.err) == "some error")
    res2 = _returning_none_err[String]("some string")
    assert_true(not res2 and res2.err and str(res2.err) == "some error")
    res3 = _returning_none_err[StringLiteral]("some string")
    assert_true(not res3 and res3.err and str(res3.err) == "some error")
    res4 = _returning_none_err("some string")
    assert_true(not res4 and res4.err and str(res4.err) == "some error")


def test_error_transfer():
    res1 = _returning_transferred_err(String("some string"))
    assert_true(res1 is None and str(res1.err) == "some error")
    res2 = _returning_transferred_err[String]("some string")
    assert_true(res2 is None and str(res2.err) == "some error")
    res3 = _returning_transferred_err[StringLiteral]("some string")
    assert_true(res3 is None and str(res3.err) == "some error")
    res4 = _returning_transferred_err("some string")
    assert_true(res4 is None and str(res4.err) == "some error")


def test_returning_err():
    item_s = _returning_err(String("string"))
    assert_true(not item_s and item_s.err and str(item_s.err) == "something")
    # item_ti = _returning_err(Tuple[Int]())
    # assert_true(not item_ti and item_ti.err and str(item_ti.err) == "something")
    # item_ts = _returning_err(Tuple[String]())
    # assert_true(not item_ts and item_ts.err and str(item_ts.err) == "something")
    item_li = _returning_err(List[Int]())
    assert_true(not item_li and item_li.err and str(item_li.err) == "something")
    item_ls = _returning_err(List[String]())
    assert_true(not item_ls and item_ls.err and str(item_ls.err) == "something")
    item_dii = _returning_err(Dict[Int, Int]())
    assert_true(
        not item_dii and item_dii.err and str(item_dii.err) == "something"
    )
    item_dss = _returning_err(Dict[String, String]())
    assert_true(
        not item_dss and item_dss.err and str(item_dss.err) == "something"
    )
    item_oi = _returning_err(Result[Int]())
    assert_true(not item_oi and item_oi.err and str(item_oi.err) == "something")
    item_os = _returning_err(Result[String]())
    assert_true(not item_os and item_os.err and str(item_os.err) == "something")


def test_returning_ok():
    # this one would fail if the String gets implicitly cast to Error(src: String)
    item_s = _returning_ok(String("string"))
    assert_true(item_s and not item_s.err and str(item_s.err) == "")
    # item_ti = _returning_ok(Tuple[Int]())
    # assert_true(item_ti and not item_ti.err and str(item_ti.err) == "")
    # item_ts = _returning_ok(Tuple[String]())
    # assert_true(item_ts and not item_ts.err and str(item_ts.err) == "")
    item_li = _returning_ok(List[Int]())
    assert_true(item_li and not item_li.err and str(item_li.err) == "")
    item_ls = _returning_ok(List[String]())
    assert_true(item_ls and not item_ls.err and str(item_ls.err) == "")
    item_dii = _returning_ok(Dict[Int, Int]())
    assert_true(item_dii and not item_dii.err and str(item_dii.err) == "")
    item_dss = _returning_ok(Dict[String, String]())
    assert_true(item_dss and not item_dss.err and str(item_dss.err) == "")
    item_oi = _returning_ok(Result[Int]())
    assert_true(item_oi and not item_oi.err and str(item_oi.err) == "")
    item_os = _returning_ok(Result[String]())
    assert_true(item_os and not item_os.err and str(item_os.err) == "")


def test_basic():
    a = Result(1)
    b = Result[Int]()

    assert_true(a)
    assert_false(b)

    assert_true(a and True)
    assert_true(True and a)
    assert_false(a and False)

    assert_false(b and True)
    assert_false(b and False)

    assert_true(a or True)
    assert_true(a or False)

    assert_true(b or True)
    assert_false(b or False)

    assert_equal(1, a.value())

    # Test invert operator
    assert_false(~a)
    assert_true(~b)

    # TODO(27776): can't inline these, they need to be mutable lvalues
    a1 = a.or_else(2)
    b1 = b.or_else(2)

    assert_equal(1, a1)
    assert_equal(2, b1)

    assert_equal(1, a.value())

    # TODO: this currently only checks for mutable references.
    # We may want to come back and add an immutable test once
    # there are the language features to do so.
    a2 = Result(1)
    a2.value() = 2
    assert_equal(a2.value(), 2)


def test_result_is():
    a = Result(1)
    assert_false(a is None)

    a = Result[Int]()
    assert_true(a is None)


def test_result_isnot():
    a = Result(1)
    assert_true(a is not None)

    a = Result[Int]()
    assert_false(a is not None)


fn _do_something(i: Int) -> Result2[Int, "IndexError"]:
    if i < 0:
        return None, Error2["IndexError"]("index out of bounds: " + str(i))
    return 1


fn _do_some_other_thing() -> Result2[String, "OtherError"]:
    a = _do_something(-1)
    if a.err:
        print(str(a.err))  # IndexError: index out of bounds: -1
        return a
    return "success"


def test_result2():
    res = _do_some_other_thing()
    assert_false(res)
    assert_equal(res.err.message, "index out of bounds: -1")


def main():
    test_basic()
    test_result_is()
    test_result_isnot()
    test_returning_ok()
    test_returning_err()
    test_error_transfer()
    test_none_err_constructor()
    test_result2()
