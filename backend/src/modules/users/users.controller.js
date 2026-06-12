// ============================================
// Users Controller
// ============================================
const usersService = require('./users.service');
const { successResponse } = require('../../utils/helpers');

async function getProfile(req, res, next) {
  try {
    const result = await usersService.getProfile(req.user.id);
    return successResponse(res, 'Profile loaded', result);
  } catch (error) {
    next(error);
  }
}

async function updateProfile(req, res, next) {
  try {
    const result = await usersService.updateProfile(req.user.id, req.body);
    return successResponse(res, result.message, result);
  } catch (error) {
    next(error);
  }
}

async function changePassword(req, res, next) {
  try {
    const result = await usersService.changePassword(req.user.id, req.body);
    return successResponse(res, result.message);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getProfile,
  updateProfile,
  changePassword,
};