from testing import assert_equal, assert_false, assert_true, assert_almost_equal

from forge_tools.complex import Quaternion, DualQuaternion


fn test_quaternion_ops() raises:
    q1 = Quaternion(2, 3, 4, 5)
    q2 = Quaternion(2, 3, 4, 5)
    q3 = Quaternion(5, 4, 3, 2)
    assert_almost_equal(7.348, q1.__abs__(), rtol=0.1)
    assert_almost_equal(Quaternion(4, 6, 8, 10).vec, (q1 + q2).vec, rtol=0.1)
    assert_almost_equal(Quaternion(0, 0, 0, 0).vec, (q1 - q2).vec, rtol=0.1)
    assert_almost_equal(
        Quaternion(-46, 12, 16, 20).vec, (q1 * q2).vec, rtol=0.1
    )
    assert_almost_equal((q1 * q2).vec, (q2 * q1).vec, rtol=0.1)
    assert_almost_equal(
        Quaternion(-24, 16, 40, 22).vec, (q1 * q3).vec, rtol=0.1
    )
    assert_almost_equal(
        Quaternion(-24, 30, 12, 36).vec, (q3 * q1).vec, rtol=0.1
    )
    assert_almost_equal(
        Quaternion(0.0925926, -0.0740741, -0.0555556, -0.037037).vec,
        q3.inverse().vec,
        rtol=0.1,
    )
    assert_almost_equal(
        Quaternion(0.037037, -0.0555556, -0.0740741, -0.0925926).vec,
        q1.inverse().vec,
        rtol=0.1,
    )
    assert_almost_equal(
        Quaternion(0.8148, 0.2593, 0, 0.5185).vec, (q1 / q3).vec, rtol=0.1
    )
    assert_almost_equal(
        Quaternion(0.8148, -0.2593, 0, -0.5185).vec, (q3 / q1).vec, rtol=0.1
    )
    # TODO
    # assert_almost_equal(..., q1**3)
    # assert_almost_equal(..., q1.exp())
    # assert_almost_equal(..., q1.ln())
    # assert_almost_equal(..., q1.sqrt())
    # assert_almost_equal(..., q1.phi())


fn test_quaternion_matrix() raises:
    # TODO
    # q1 = Quaternion(2, 3, 4, 5)
    # assert_almost_equal(
    #     List(
    #         -14 / 27,
    #         2 / 27,
    #         23 / 27,
    #         22 / 27,
    #         -7 / 27,
    #         14 / 27,
    #         7 / 27,
    #         26 / 27,
    #         2 / 27,
    #     ),
    #     q1.to_matrix(),
    #     rtol=0.1,
    # )
    pass


fn test_dualquaternion_ops() raises:
    q1 = DualQuaternion(2, 3, 4, 5, 6, 7, 8, 9)
    q2 = DualQuaternion(2, 3, 4, 5, 6, 7, 8, 9)
    q3 = DualQuaternion(9, 8, 7, 6, 5, 4, 3, 2)
    assert_almost_equal(
        DualQuaternion(4, 6, 8, 10, 12, 14, 16, 18).vec, (q1 + q2).vec, rtol=0.1
    )
    assert_almost_equal(
        DualQuaternion(0, 0, 0, 0, 0, 0, 0, 0).vec, (q1 - q2).vec, rtol=0.1
    )
    assert_almost_equal(
        DualQuaternion(-46, 12, 16, 20, -172, 64, 80, 96).vec,
        (q1 * q2).vec,
        rtol=0.1,
    )
    assert_almost_equal((q1 * q2).vec, (q2 * q1).vec, rtol=0.1)
    assert_almost_equal(
        DualQuaternion(-64, 32, 72, 46, -136, 112, 184, 124).vec,
        (q1 * q3).vec,
        rtol=0.1,
    )
    assert_almost_equal(
        DualQuaternion(-64, 54, 28, 68, -136, 156, 96, 168).vec,
        (q3 * q1).vec,
        rtol=0.1,
    )
    # TODO
    # assert_almost_equal(..., q1**3)


fn test_dualquaternion_matrix() raises:
    # TODO
    pass


fn test_dualquaternion_screw() raises:
    # TODO
    pass


fn main() raises:
    test_quaternion_ops()
    test_quaternion_matrix()
    test_dualquaternion_ops()
    test_dualquaternion_matrix()
    test_dualquaternion_screw()
