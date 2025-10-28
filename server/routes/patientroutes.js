const router = require('express').Router();
const patientController = require("../controllers/patientController");

router.post("/" , patientController.createPatient);

router.get("/:id", patientController.getPatientByclinicId);

router.put("/:id", patientController.updatePatient);

router.delete("/:id" , patientController.deletePatient);


module.exports = router;