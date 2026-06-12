// ============================================
// Showtimes Controller
// ============================================
const showtimesService = require('./showtimes.service');
const { successResponse } = require('../../utils/helpers');

async function getShowtimes(req, res, next) {
  try {
    const { movieId, cinemaId, date } = req.query;
    const showtimes = await showtimesService.getShowtimes({ movieId, cinemaId, date });
    return successResponse(res, 'Showtimes list', { showtimes });
  } catch (error) {
    next(error);
  }
}

async function getShowtimeById(req, res, next) {
  try {
    const id = parseInt(req.params.id);
    const showtime = await showtimesService.getShowtimeById(id);
    return successResponse(res, 'Showtime detail and seat status', { showtime });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getShowtimes,
  getShowtimeById,
};
