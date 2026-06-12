// ============================================
// Cinemas Controller
// ============================================
const cinemasService = require('./cinemas.service');
const { successResponse } = require('../../utils/helpers');

async function getCinemas(req, res, next) {
  try {
    const cinemas = await cinemasService.getCinemas();
    return successResponse(res, 'Cinemas list', { cinemas });
  } catch (error) {
    next(error);
  }
}

async function getCinemaById(req, res, next) {
  try {
    const id = parseInt(req.params.id);
    const cinema = await cinemasService.getCinemaById(id);
    return successResponse(res, 'Cinema detail', { cinema });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getCinemas,
  getCinemaById,
};
// 
