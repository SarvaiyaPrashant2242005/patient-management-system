const {DataTypes} = require("sequelize");
const sequelize = require("../config/db");


const Patient = require("./patient");

const Prescription = sequelize.define('Prescription' , {
    id : {
        type : DataTypes.INTEGER,
        primaryKey : true,
        autoIncrement : true
    },
    patient_id : {
        type : DataTypes.INTEGER,
        allowNull : false,
        references : {
            model : Patient,
            key : 'id'
        },
        onUpdate : 'CASCADE',
        onDelete : 'CASCADE'
    },
    date : {
        type : DataTypes.DATE,
        allowNull : false
    },
    dieases : {
        type : DataTypes.STRING,
        allowNull : false
    },
    symptoms : {
        type : DataTypes.STRING,
        allowNull : false
    },
    payment_mode : {
        type : DataTypes.ENUM('case' , 'online'),
        allowNull : false
    }
},{
    tableName : 'prescription',
    timestamps : true,
})

Patient.hasMany(Prescription, {foreignKey : 'patient_id'});
Prescription.belongsTo(Patient, {foreignKey : 'patient_id'});


module.exports = Prescription;