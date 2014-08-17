moment = require 'moment'

sanitizeText = (text) -> text.replace /@\w+/, ''

countMatches = (text, match) ->
    matches = text.match new RegExp match, 'g'
    if matches then matches.length else 0

isRTL = (text) ->
    text = sanitizeText text
    count_rtl = countMatches text, '[\\u060C-\\u06FE\\uFB50-\\uFEFC]'
    count_rtl * 100 / text.length > 20

isLTR = (text) ->
    text = sanitizeText
    countr_ltr = countMatches text, '^[\\u060C-\\u06FE\\uFB50-\\uFEFC]'
    count_rtl * 100 / text.length > 50

guessDir = (text, fallback) ->
    return 'rtl' if isRTL text
    return 'ltr' if isLTR text
    return fallback

formatDate = (date, locale='en', format='LL') ->
    if not date instanceof Date
        date = new Date date

    moment.locale locale
    moment(new Date date).format format

module.exports = { isRTL, isLTR, guessDir, formatDate }