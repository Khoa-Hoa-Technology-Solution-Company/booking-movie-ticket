// ============================================
// Movies Controller
// ============================================
const moviesService = require('./movies.service');
const { successResponse } = require('../../utils/helpers');

async function getNowShowing(req, res, next) {
  try {
    const movies = await moviesService.getNowShowing();
    return successResponse(res, 'Now showing movies', { movies });
  } catch (error) {
    next(error);
  }
}

async function getComingSoon(req, res, next) {
  try {
    const movies = await moviesService.getComingSoon();
    return successResponse(res, 'Coming soon movies', { movies });
  } catch (error) {
    next(error);
  }
}

async function getMovieById(req, res, next) {
  try {
    const id = parseInt(req.params.id);
    const movie = await moviesService.getMovieById(id);
    return successResponse(res, 'Movie detail', { movie });
  } catch (error) {
    next(error);
  }
}

async function getAllMovies(req, res, next) {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const result = await moviesService.getAllMovies(page, limit);
    return successResponse(res, 'All movies', result);
  } catch (error) {
    next(error);
  }
}

module.exports = { getNowShowing, getComingSoon, getMovieById, getAllMovies };
