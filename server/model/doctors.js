const {DataTypes} = require('sequelize');
const sequelize = require("../config/db");
const bcrypt = require("bcrypt");

const Doctor = sequelize.define('Doctor' , {
    id :{
        type : DataTypes.INTEGER,
        primaryKey : true,
        autoIncrement : true
    },
    email : {
        type : DataTypes.STRING,
        allowNull : false,
        unique : true,
        validate : {
            isEmail : true
        }
    },
    fullname : {
        type : DataTypes.STRING,
        allowNull : false
    },
    degree : {
        type : DataTypes.STRING,
        allowNull : true
    },
    phoneNo : {
        type : DataTypes.STRING,
        allowNull : true
    },
    password : {
        type : DataTypes.STRING,
        allowNull : false
    }
}, {
    tableName : 'Doctor',
    timestamps : false,
    hooks : {
        beforeCreate : async (user) => {
            if(user.password) {
                user.password = await bcrypt.hash(user.password, 10);
            }
        },
        beforeUpdate : async (user) => {
            if(user.changed('password')) {
                user.password = await bcrypt.hash(user.password);
            }
        }
    }
})

Doctor.prototype.validatePassword = async function(password) {
  return await bcrypt.compare(password, this.password);
};

module.exports = Doctor;