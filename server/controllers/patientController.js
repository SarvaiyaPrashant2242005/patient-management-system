const Clinic = require('../model/clinic');
const Doctor = require('../model/doctors');
const Patient = require('../model/patient');


const patientController = {
    createPatient: async (req, res) => {
        try {
            const { name, gender, contact, dob, height, weight, photo, doctorId, clinicId } = req.body;

            if (!name || !gender || !contact || !dob || !doctorId || !clinicId) {
                return res.status(400).json({
                    success: false,
                    messege: "name, gender, contact , dob , doctor id or clinic id is required"
                });
            }

            const doctor = await Doctor.findByPk(doctorId);
            const clinic = await Clinic.findByPk(clinicId);

            if (!doctor || !clinic) {
                return res.status(404).json({
                    success: false,
                    messege: "DOctor or Clinic not found"
                })
            }

            const patient = await Patient.create({
                name,
                gender,
                contact,
                dob,
                height,
                weight,
                photo,
                doctorId,
                clinicId
            });
            res.status(201).json({
                success: true,
                messege: 'Patient added Successfully',
                data: patient
            });
        }
        catch (err) {
            res.status(500).json({
                success: false,
                messege: "Error while creating clinic",
                error: err.messege
            })
        }
    },

getPatientByclinicId: async (req, res) => {
  try {
    const { id } = req.params; // clinicId

    const patients = await Patient.findAll({
      where: { clinicId: id },
      include: [{
        model: Clinic,
        attributes: ['id', 'name', 'landlineNo', 'doctorName', 'address']
      }]
    });

    if (patients.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No patients found for this clinic'
      });
    }

    res.status(200).json({
      success: true,
      data: patients
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Error fetching patients',
      error: err.message
    });
  }
},


    updatePatient : async (req,res) => {
        try {
            const {id} = req.params;
            const {name, gender, contact, dob, height, weight,photo} = req.body;

            const patient = await Patient.findByPk(id);

            if(!patient) {
                return res.status(404).json({
                    success : false,
                    messege : "Patient not found"
                });
            }

            await patient.update({
                name : name || patient.name,
                gender : gender || patient.gender,
                contact : contact !== undefined ? contact : patient.conatct,
                dob : dob || patient.dob,
                height : height || patient.height,
                weight : weight || patient.weight,
                photo : photo || patient.photo
            });

            res.status(200).json({
                success : true,
                messege : "Patient updated",
                data : patient
            });
        }
        catch(err){
            res.status(500).json({
                success : false,
                messege : "Error updating patient",
                error : err.messege
            })
        }
    },
    deletePatient : async (req, res) => {
         try{
            const {id} = req.body;

            const patient = await Patient.findByPk(id);

            if(!patient) {
                return res.status(404).json({
                    success : false,
                    messege : "Patient not found"
                })
            }

            await patient.destroy();
            res.status|(200).json({
                success : true,
                messege  : "Patient Deleted Successfully"
            })
         }catch(err){
            res.status(500).json({
                success : false,
                messege : "Error deleting patient",
                error : err.messege
            })
         }
    }
}


module.exports = patientController;