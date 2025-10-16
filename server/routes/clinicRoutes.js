const express = require('express');
const router = express.Router();
const clinicController = require('../controllers/clinicController');

// Create a new clinic
router.post('/', clinicController.createClinic);

// Get all clinics
router.get('/', clinicController.getAllClinics);

// Get clinic by ID
router.get('/:id', clinicController.getClinicById);

// Get clinics by doctor ID
router.get('/doctor/:doctorId', clinicController.getClinicsByDoctorId);

// Update clinic
router.put('/:id', clinicController.updateClinic);

// Delete clinic
router.delete('/:id', clinicController.deleteClinic);

module.exports = router;