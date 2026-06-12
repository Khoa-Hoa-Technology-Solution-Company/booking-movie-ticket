// ============================================
// Users Routes
// ============================================
const { Router } = require('express');
const usersController = require('./users.controller');
const { authenticate } = require('../../middleware/auth');
const { validate, updateProfileSchema, changePasswordSchema } = require('./users.validator');

const router = Router();

router.use(authenticate);

router.get('/profile', usersController.getProfile);
router.put('/profile', validate(updateProfileSchema), usersController.updateProfile);
router.put('/change-password', validate(changePasswordSchema), usersController.changePassword);

module.exports = router;