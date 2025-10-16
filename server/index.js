const express = require('express');
const cors = require('cors');
require('dotenv').config();
const sequelize = require("./config/db");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({extended : true}));


// Health check
app.get('/', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Server is running', server : "medtrack" });
});


sequelize.authenticate()
.then(() => {
    console.log('DATABASE CONNECTED');
    return sequelize.sync({alter : true});
})
.then(()=>{
    app.listen(PORT, () => {
        console.log(`🚀 Server is running on port ${PORT}`); 
    });
})
  .catch(err => {
    console.error('❌ Unable to connect to database:', err);
    process.exit(1);
  });

