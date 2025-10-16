const Doctor = require("../model/doctors");
const jwt = require("jsonwebtoken");

const doctorController = {
    register: async (req, res) => {
        try {
            const { fullname, email, degree, password, phoneNo } = req.body;

            // BUG FIX #1: Added 'await'
            const doctor = await Doctor.create({
                fullname,
                email,
                degree,
                password,
                phoneNo
            });

            res.status(201).json({
                message: "Doctor Register Successfully",
                doctorId: doctor.id
            });
        } catch (err) {
            if (err.name === 'SequelizeUniqueConstraintError') {
                return res.status(409).json({ message: 'Email already exists' });
            }
            // Added fallback error response
            res.status(500).json({ message: 'Registration failed', error: err.message });
        }
    },

    login: async (req, res) => {
        try {
            const { email, password } = req.body;
            const doctor = await Doctor.findOne({ where: { email } });

            if (!doctor || !(await doctor.validatePassword(password))) {
                return res.status(401).json({ message: "Invalid credentials" });
            }

            const token = jwt.sign(
                {
                    id: doctor.id,
                    email: doctor.email
                },
                process.env.JWT_SECRET,
                { expiresIn: '24h' }
            );

            res.json({
                message: "Doctor Logged in",
                token,
                doctor: {
                    id: doctor.id,
                    email: doctor.email,
                    fullname: doctor.fullname,
                    degree: doctor.degree,
                    phoneNo: doctor.phoneNo
                }
            });
        } catch (err) {
            console.error(err);
            res.status(500).json({ message: 'Login failed', error: err.message });
        }
    },

   updatedoctor: async (req, res) => {
    try {
        const { id } = req.params; // Get ID from URL parameter
        const { degree, phoneNo, fullname } = req.body;
        
        // Check if doctor exists
        const doctor = await Doctor.findByPk(id);
        if (!doctor) {
            return res.status(404).json({ message: "Doctor not found" });
        }
        
        // Update only the fields that are provided
        const updateData = {};
        if (fullname) updateData.fullname = fullname;
        if (degree) updateData.degree = degree;
        if (phoneNo) updateData.phoneNo = phoneNo;
        
        await Doctor.update(
            updateData,
            { where: { id } }
        );
        
        res.json({ message: "Profile Updated Successfully!!!" });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Update failed', error: err.message });
    }
}
};

module.exports = doctorController;