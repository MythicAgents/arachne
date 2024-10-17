function(task, responses){
    if(task.status.includes("error")){
        const combined = responses.reduce( (prev, cur) => {
            return prev + cur;
        }, "");
        return {'plaintext': combined};
    }else if(task.completed){
        if(responses.length > 0){
            try{
                let data = responses[0].split("\n")[1].split(": ")[1];
                return {"media": [{
                    "filename": task.display_params,
                        "agent_file_id": data,
                    }]}
            }catch(error){
                const combined = responses.reduce( (prev, cur) => {
                    return prev + cur;
                }, "");
                return {'plaintext': combined};
            }

        }else{
            return {"plaintext": "No data to display..."}
        }

    }else{
        // this means we shouldn't have any output
        return {"plaintext": "Not response yet from agent..."}
    }
}