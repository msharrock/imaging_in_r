## ----setup, include=FALSE------------------------------------------------
library(methods)
library(ggplot2)
library(pander)
knitr::opts_chunk$set(echo = TRUE, comment = "", cache=TRUE, warning = FALSE)

## ----loading, echo=FALSE, message=FALSE----------------------------------
library(ms.lesion)
library(neurobase)
library(fslr)
library(scales)
library(oasis)
library(dplyr)
tr_files = get_image_filenames_list_by_subject(group = "training", type = "coregistered")
ts_files = get_image_filenames_list_by_subject(group = "test", type = "coregistered")
tr_t1s = lapply(tr_files, function(x) readnii(x["MPRAGE"]))
tr_t2s = lapply(tr_files, function(x) readnii(x["T2"]))
tr_flairs = lapply(tr_files, function(x) readnii(x["FLAIR"]))
tr_pds = lapply(tr_files, function(x) readnii(x["PD"]))
tr_masks = lapply(tr_files, function(x) readnii(x["Brain_Mask"]))
tr_golds1 = lapply(tr_files, function(x) readnii(x["mask1"]))
tr_golds2 = lapply(tr_files, function(x) readnii(x["mask2"]))
ts_t1s = lapply(ts_files, function(x) readnii(x["MPRAGE"]))
ts_t2s = lapply(ts_files, function(x) readnii(x["T2"]))
ts_flairs = lapply(ts_files, function(x) readnii(x["FLAIR"]))
ts_pds = lapply(ts_files, function(x) readnii(x["PD"]))
ts_masks = lapply(ts_files, function(x) readnii(x["Brain_Mask"]))
# John added for code to work
tr_golds = tr_golds2

## ----over_show_run, echo=FALSE-------------------------------------------
les_mask = tr_golds2$training05

# john code for choosing z-slice with highest # of voxels
w = which(les_mask > 0, arr.ind = TRUE)
w = as.data.frame(w, stringsAsFactors = FALSE)
keep_dim = w %>% group_by(dim3) %>% 
  tally() %>% 
  arrange(desc(n)) %>% 
  ungroup %>% slice(1) 
keep_dim = keep_dim$dim3
w = w[ w$dim3 %in% keep_dim, ]
xyz = floor(colMeans(w))
ortho2(robust_window(tr_flairs$training05), les_mask, xyz = xyz, col.y = scales::alpha("red", 0.5))

## ----default_predict_ts_show, eval=FALSE---------------------------------
## library(oasis)
## default_predict_ts = function(x){
##   res = oasis_predict(
##       flair=ts_flairs[[x]], t1=ts_t1s[[x]],
##       t2=ts_t2s[[x]], pd=ts_pds[[x]],
##       brain_mask = ts_masks[[x]],
##       preproc=FALSE, normalize=TRUE,
##       model=oasis::oasis_model)
##   return(res)
## }
## default_probs_ts = lapply(1:3, default_predict_ts)

## ----default_predict_run, eval=TRUE, echo=FALSE--------------------------
default_ts = lapply(ts_files, 
	function(x) readnii(x["Default_OASIS"]))

## ----viz_01, echo=FALSE--------------------------------------------------
les_mask = default_ts[[1]]
les_mask[les_mask<.05] = 0
ortho2(ts_flairs$test01, les_mask, xyz = xyz)

## ----viz_02, echo=FALSE--------------------------------------------------
les_mask[les_mask<.16] = 0
les_mask[les_mask!=0] = 1
ortho2(ts_flairs$test01, les_mask, col.y=alpha("red", 0.5), xyz = xyz)

## ----default_predict_tr_show, eval=FALSE---------------------------------
## default_predict_tr = function(x){
##   res = oasis_predict(
##       flair=tr_flairs[[x]], t1=tr_t1s[[x]],
##       t2=tr_t2s[[x]], pd=tr_pds[[x]],
##       brain_mask=tr_masks[[x]],
##       preproc=FALSE, normalize=TRUE,
##       model=oasis::oasis_model, binary=TRUE)
##   return(res)
## }
## default_probs_tr = lapply(1:5, default_predict_tr)

## ----default_predict_tr_run, eval=TRUE, echo=FALSE-----------------------
default_tr = lapply(tr_files, 
	function(x){
		img = readnii(x["Default_OASIS"])
		img = img > 0.16
		return(img)
	})

## ----over_05_run, echo=FALSE---------------------------------------------
les_mask = default_tr[[5]]
ortho2(tr_flairs$training05, les_mask, col.y = alpha("red", 0.5))

## ----table1, echo=FALSE--------------------------------------------------
dice = function(x){
  return((2*x[2,2])/(2*x[2,2] + x[1,2] + x[2,1]))
}
tbls_df1 = lapply(1:5, function(x) table(c(tr_golds1[[x]]), c(default_tr[[x]])))
dfDice1 = sapply(tbls_df1, dice)

tbls_df2 = lapply(1:5, function(x) table(c(tr_golds2[[x]]), c(default_tr[[x]])))
dfDice2 = sapply(tbls_df2, dice)

diceDF = data.frame('Subject'=factor(rep(1:5, 2)), 'Rater'=factor(c(rep(1, 5), rep(2, 5))), 'Dice'=c(dfDice1, dfDice2))
plot(ggplot(diceDF, aes(x=Subject, y=Dice, fill=Rater)) + geom_histogram(position="dodge", stat="identity", aes(color=Rater)))

## ----oasis_df_show, eval=FALSE-------------------------------------------
## make_df = function(x){
##   res = oasis_train_dataframe(
##       flair=tr_flairs[[x]], t1=tr_t1s[[x]], t2=tr_t2s[[x]],
##       pd=tr_pds[[x]], gold_standard=tr_golds2[[x]],
##       brain_mask=tr_masks[[x]],
##       preproc=FALSE, normalize=TRUE, return_preproc=FALSE)
##   return(res$oasis_dataframe)
## }
## oasis_dfs = lapply(1:5, make_df)

## ----oasis_model_show, eval=FALSE----------------------------------------
## ms_model = do.call("oasis_training", oasis_dfs)

## ----oasis_model_show2---------------------------------------------------
print(ms.lesion::ms_model)

## ----trained_predict_tr_run, eval=TRUE, echo=FALSE-----------------------
trained_tr = lapply(tr_files, 
  function(x){
    img = readnii(x["Trained_OASIS"])
    img = img > 0.16
    return(img)
  })

## ----table3, echo=FALSE--------------------------------------------------
tbls_tr1 = lapply(1:5, function(x) table(c(tr_golds1[[x]]), c(trained_tr[[x]])))
trDice1 = sapply(tbls_tr1, dice)

tbls_tr2 = lapply(1:5, function(x) table(c(tr_golds2[[x]]), c(trained_tr[[x]])))
trDice2 = sapply(tbls_tr2, dice)

diceTR = data.frame('Subject'=factor(rep(1:5, 2)), 'Rater'=factor(c(rep(1, 5), rep(2, 5))), 'Dice'=c(trDice1, trDice2))
diceDF$Model = "Default"
diceTR$Model = "Trained"
diceAll = rbind(diceDF, diceTR)
diceAll$Model = factor(diceAll$Model)

plot(ggplot(diceAll, aes(x=Subject, y=Dice, fill=Rater)) + geom_histogram(position="dodge", stat="identity", aes(color=Rater)) + facet_wrap(~Model))

## ----dice_mat, echo = FALSE----------------------------------------------
df = cbind(id = sprintf("%02.0f", 1:5),
           r1 = round((trDice1 - dfDice1) / dfDice1 * 100, 1),
           r2 = round((trDice2 - dfDice2) / dfDice2 * 100, 1))
df = data.frame(df, stringsAsFactors = FALSE)
colnames(df) = c("ID", "Rater 1", "Rater 2")

## ---- echo = FALSE-------------------------------------------------------
pander(df)

